from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import uuid4

from bson import ObjectId
from pymongo import ReturnDocument

from app.db.mongodb import db_instance
from app.schemas.category import CategoryCreate, CategoryUpdate


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _serialize_category(doc: Dict[str, Any]) -> Dict[str, Any]:
    category = dict(doc)
    raw_object_id = category.get("_id")
    logical_id = category.get("id") or (str(raw_object_id) if raw_object_id else "")
    category["id"] = str(logical_id)
    category.pop("_id", None)
    category["user_id"] = str(category.get("user_id", ""))

    for field in ("updated_at",):
        field_value = category.get(field)
        if isinstance(field_value, datetime):
            category[field] = _as_utc(field_value).isoformat()

    if not category.get("updated_at"):
        category["updated_at"] = _utcnow().isoformat()

    category["is_deleted"] = bool(category.get("is_deleted", False))
    category["name"] = str(category.get("name", ""))
    category["icon"] = str(category.get("icon", "folder"))
    category["color_hex"] = str(category.get("color_hex", "#2196F3"))
    return category


def _category_query(category_id: str, user_id: str) -> Dict[str, Any]:
    or_conditions: List[Dict[str, Any]] = [{"id": category_id}]
    if ObjectId.is_valid(category_id):
        or_conditions.append({"_id": ObjectId(category_id)})
    return {"user_id": user_id, "$or": or_conditions}


class CRUDCategory:
    def __init__(self, collection_name: str):
        self.collection_name = collection_name

    @property
    def collection(self):
        return db_instance.db[self.collection_name]

    async def create(self, user_id: str, obj_in: CategoryCreate) -> Dict[str, Any]:
        obj_dict = obj_in.model_dump(exclude_none=True)
        logical_id = obj_dict.pop("id", None) or str(uuid4())
        now = _utcnow()

        obj_dict.update(
            {
                "id": logical_id,
                "user_id": user_id,
                "updated_at": now,
                "is_deleted": bool(obj_dict.get("is_deleted", False)),
            }
        )

        updated = await self.collection.find_one_and_update(
            {"user_id": user_id, "id": logical_id},
            {"$set": obj_dict},
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )
        if not updated:
            updated = await self.collection.find_one({"user_id": user_id, "id": logical_id})
        return _serialize_category(updated)

    async def get_multi(
        self,
        user_id: str,
        skip: int = 0,
        limit: int = 100,
        include_deleted: bool = False,
    ) -> List[Dict[str, Any]]:
        query: Dict[str, Any] = {"user_id": user_id}
        if not include_deleted:
            query["is_deleted"] = {"$ne": True}

        cursor = (
            self.collection.find(query).sort("updated_at", -1).skip(skip).limit(limit)
        )
        categories = await cursor.to_list(length=limit)
        return [_serialize_category(cat) for cat in categories]

    async def update(
        self, id: str, user_id: str, obj_in: CategoryUpdate
    ) -> Optional[Dict[str, Any]]:
        update_data = {
            k: v for k, v in obj_in.model_dump(exclude_none=True).items() if v is not None
        }
        if not update_data:
            existing = await self.collection.find_one(_category_query(id, user_id))
            return _serialize_category(existing) if existing else None

        update_data["updated_at"] = _utcnow()
        result = await self.collection.find_one_and_update(
            _category_query(id, user_id),
            {"$set": update_data},
            return_document=ReturnDocument.AFTER,
        )
        if result:
            return _serialize_category(result)
        return None

    async def remove(self, id: str, user_id: str) -> bool:
        removed = await self.collection.find_one_and_delete(_category_query(id, user_id))
        if not removed:
            return False

        logical_id = str(removed.get("id") or id)
        await db_instance.db["events"].update_many(
            {"user_id": user_id, "category_id": logical_id},
            {"$set": {"category_id": None, "updated_at": _utcnow()}},
        )
        return True


category = CRUDCategory("categories")
