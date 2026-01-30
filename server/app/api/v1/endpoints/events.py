from fastapi import APIRouter, HTTPException, Depends, Body, status
from typing import List, Any, Dict, Optional
from bson import ObjectId
from datetime import datetime
from app.db.mongodb import db_instance
from app.schemas.event import EventCreate, EventOut
from app.api.v1.endpoints.auth import get_current_user

router = APIRouter()

@router.get("/")
async def get_events(current_user: Any = Depends(get_current_user)):
    db = db_instance.db
    # gei id of current user
    user_id_str = str(current_user["_id"])
    
    # filter: only my tasks and only not deleted ones
    query = {
        "user_id": user_id_str,
        "is_deleted": {"$ne": True}
    }
    
    cursor = db["events"].find(query)
    events = await cursor.to_list(length=100)
    
    print(f"\n--- LOG: Found {len(events)} events for user {user_id_str} ---")

    formatted_events = []
    for event in events:
        try:
            # 1. change system id to str id
            if "_id" in event:
                event["id"] = str(event.pop("_id"))
            
            # 2. clear all fields from obj id
            for key, value in event.items():
                if isinstance(value, ObjectId):
                    event[key] = str(value)
            
            # 3. def values if old data
            event.setdefault("is_completed", False)
            event.setdefault("is_deleted", False)
            event.setdefault("priority", 2)
            
            # 4. turbn dates into ISO for flutter
            for date_field in ["updated_at", "start_at", "end_at"]:
                if date_field in event and isinstance(event[date_field], datetime):
                    event[date_field] = event[date_field].isoformat()
            
            if "updated_at" not in event:
                event["updated_at"] = datetime.utcnow().isoformat()

            formatted_events.append(event)
        except Exception as e:
            print(f"!!! Error formatting event: {e}")

    return formatted_events

@router.post("/", response_model=EventOut)
async def create_event(event_in: EventCreate, current_user: Any = Depends(get_current_user)):
    db = db_instance.db
    event_dict = event_in.dict()
    
    # connect task with user
    event_dict["user_id"] = str(current_user["_id"])
    event_dict["updated_at"] = datetime.utcnow()
    event_dict["is_deleted"] = False
    
    result = await db["events"].insert_one(event_dict)
    
    # Вreturn object, turning _id to id
    event_dict["id"] = str(result.inserted_id)
    if "_id" in event_dict:
        event_dict.pop("_id")
        
    return event_dict

@router.patch("/{event_id}")
async def update_event(
    event_id: str, 
    updates: Dict[str, Any] = Body(...),
    current_user: Any = Depends(get_current_user)
):
    db = db_instance.db
    user_id_str = str(current_user["_id"])
    
    # search task by id and check user
    query_parts = [{"id": event_id}, {"user_id": user_id_str}]
    if ObjectId.is_valid(event_id):
        query_parts.append({"_id": ObjectId(event_id)})
    
    # user can update only his own tasks
    query = {
        "$and": [
            {"$or": [item for item in query_parts if "user_id" not in item]},
            {"user_id": user_id_str}
        ]
    }

    # map fields from frontend
    if "isCompleted" in updates:
        updates["is_completed"] = updates.pop("isCompleted")
    if "categoryId" in updates:
        updates["category_id"] = updates.pop("categoryId")

    updates["updated_at"] = datetime.utcnow()

    result = await db["events"].update_one(query, {"$set": updates})

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Event not found or access denied")

    return {"status": "success"}

@router.delete("/{event_id}")
async def delete_event(event_id: str, current_user: Any = Depends(get_current_user)):
    db = db_instance.db
    user_id_str = str(current_user["_id"])
    
    query = {
        "user_id": user_id_str,
        "$or": [
            {"id": event_id},
            {"_id": ObjectId(event_id) if ObjectId.is_valid(event_id) else None}
        ]
    }
    # cleal filter from non valid obj id
    if not ObjectId.is_valid(event_id):
        query["$or"] = [{"id": event_id}]

    result = await db["events"].update_one(query, {"$set": {"is_deleted": True}})
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Event not found")
        
    return {"status": "deleted"}