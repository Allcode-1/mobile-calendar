from datetime import datetime, timezone
from typing import Any, Dict, List
from uuid import uuid4

from bson import ObjectId
from fastapi import APIRouter, Body, Depends, HTTPException, Query
from pymongo import ReturnDocument

from app.api.v1.endpoints.auth import get_current_user
from app.db.mongodb import db_instance
from app.schemas.event import EventCreate, EventOut, EventUpdate, SyncSchema

router = APIRouter()


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _event_query(event_id: str, user_id: str) -> Dict[str, Any]:
    or_conditions: List[Dict[str, Any]] = [{"id": event_id}]
    if ObjectId.is_valid(event_id):
        or_conditions.append({"_id": ObjectId(event_id)})
    return {"user_id": user_id, "$or": or_conditions}


async def _ensure_logical_id(doc: Dict[str, Any]) -> str:
    if doc.get("id"):
        return str(doc["id"])

    logical_id = str(doc["_id"])
    await db_instance.db["events"].update_one(
        {"_id": doc["_id"]},
        {"$set": {"id": logical_id}},
    )
    doc["id"] = logical_id
    return logical_id


def _serialize_event(doc: Dict[str, Any]) -> Dict[str, Any]:
    event = dict(doc)
    event.pop("_id", None)

    event["id"] = str(event.get("id") or "")
    event["user_id"] = str(event.get("user_id", ""))
    event.setdefault("is_completed", False)
    event.setdefault("is_deleted", False)

    priority = event.get("priority")
    if not isinstance(priority, int) or priority < 1 or priority > 3:
        event["priority"] = 2

    reminder = event.get("remind_before")
    if reminder is not None:
        try:
            reminder = int(reminder)
        except (TypeError, ValueError):
            reminder = None
        if reminder is not None and reminder < 0:
            reminder = None
    event["remind_before"] = reminder

    for field in ("updated_at", "start_at", "end_at"):
        field_value = event.get(field)
        if isinstance(field_value, datetime):
            event[field] = _as_utc(field_value).isoformat()

    if "updated_at" not in event:
        event["updated_at"] = _utcnow().isoformat()

    return event


@router.get("/", response_model=List[EventOut])
async def get_events(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=200, ge=1, le=1000),
    include_deleted: bool = Query(default=False),
    current_user: Any = Depends(get_current_user),
):
    db = db_instance.db
    user_id_str = str(current_user["_id"])

    query: Dict[str, Any] = {"user_id": user_id_str}
    if not include_deleted:
        query["is_deleted"] = {"$ne": True}

    cursor = (
        db["events"]
        .find(query)
        .sort("updated_at", -1)
        .skip(skip)
        .limit(limit)
    )

    formatted_events: List[Dict[str, Any]] = []
    async for event in cursor:
        await _ensure_logical_id(event)
        formatted_events.append(_serialize_event(event))

    return formatted_events


@router.post("/", response_model=EventOut)
async def create_event(
    event_in: EventCreate,
    current_user: Any = Depends(get_current_user),
):
    db = db_instance.db
    user_id_str = str(current_user["_id"])

    event_dict = event_in.model_dump(exclude_none=True)
    event_id = event_dict.pop("id", None) or str(uuid4())
    event_dict.update(
        {
            "id": event_id,
            "user_id": user_id_str,
            "updated_at": _utcnow(),
            "is_deleted": event_dict.get("is_deleted", False),
        }
    )

    updated = await db["events"].find_one_and_update(
        {"user_id": user_id_str, "id": event_id},
        {"$set": event_dict},
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )
    if not updated:
        updated = await db["events"].find_one({"user_id": user_id_str, "id": event_id})

    return _serialize_event(updated)


@router.patch("/{event_id}", response_model=EventOut)
async def update_event(
    event_id: str,
    updates: EventUpdate = Body(...),
    current_user: Any = Depends(get_current_user),
):
    db = db_instance.db
    user_id_str = str(current_user["_id"])

    update_data = updates.model_dump(exclude_unset=True, by_alias=False)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    update_data["updated_at"] = _utcnow()

    updated = await db["events"].find_one_and_update(
        _event_query(event_id, user_id_str),
        {"$set": update_data},
        return_document=ReturnDocument.AFTER,
    )

    if not updated:
        raise HTTPException(status_code=404, detail="Event not found or access denied")

    await _ensure_logical_id(updated)
    return _serialize_event(updated)


@router.delete("/{event_id}")
async def delete_event(event_id: str, current_user: Any = Depends(get_current_user)):
    db = db_instance.db
    user_id_str = str(current_user["_id"])

    updated = await db["events"].find_one_and_update(
        _event_query(event_id, user_id_str),
        {"$set": {"is_deleted": True, "updated_at": _utcnow()}},
        return_document=ReturnDocument.AFTER,
    )

    if not updated:
        raise HTTPException(status_code=404, detail="Event not found")

    await _ensure_logical_id(updated)
    return {"status": "deleted", "id": str(updated["id"])}


@router.post("/sync", response_model=List[EventOut])
async def sync_events(
    payload: SyncSchema,
    current_user: Any = Depends(get_current_user),
):
    db = db_instance.db
    user_id_str = str(current_user["_id"])

    for incoming in payload.events:
        client_data = incoming.model_dump(exclude_none=True)
        event_id = client_data["id"]

        client_data["id"] = event_id
        client_data["user_id"] = user_id_str
        client_data["updated_at"] = _as_utc(client_data.get("updated_at")) or _utcnow()
        client_data["is_deleted"] = client_data.get("is_deleted", False)
        priority = client_data.get("priority", 2)
        if not isinstance(priority, int) or priority < 1 or priority > 3:
            priority = 2
        client_data["priority"] = priority

        reminder = client_data.get("remind_before")
        if reminder is not None:
            try:
                reminder = int(reminder)
            except (TypeError, ValueError):
                reminder = None
        if reminder is not None and reminder < 0:
            reminder = None
        client_data["remind_before"] = reminder

        lookup_query: Dict[str, Any] = {"user_id": user_id_str, "$or": [{"id": event_id}]}
        if ObjectId.is_valid(event_id):
            lookup_query["$or"].append({"_id": ObjectId(event_id)})

        existing = await db["events"].find_one(lookup_query)
        if not existing:
            await db["events"].insert_one(client_data)
            continue

        server_updated_at = _as_utc(existing.get("updated_at"))
        client_updated_at = client_data["updated_at"]

        if not server_updated_at or client_updated_at > server_updated_at:
            await db["events"].update_one(
                {"_id": existing["_id"]},
                {"$set": client_data},
            )
        elif not existing.get("id"):
            await db["events"].update_one(
                {"_id": existing["_id"]},
                {"$set": {"id": event_id}},
            )

    cursor = db["events"].find({"user_id": user_id_str}).sort("updated_at", -1)
    synced_events: List[Dict[str, Any]] = []
    async for event in cursor:
        await _ensure_logical_id(event)
        synced_events.append(_serialize_event(event))

    return synced_events
