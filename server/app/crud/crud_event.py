from typing import Any, List, Optional
from datetime import datetime, timezone
from bson import ObjectId
from app.crud.base import CRUDBase
from app.schemas.event import EventCreate, EventBase 

class CRUDEvent(CRUDBase[Any, EventCreate, EventBase]):
    
    async def create(self, user_id: str, *, obj_in: Any):
        obj_data = obj_in if isinstance(obj_in, dict) else obj_in.model_dump()
        obj_data.update({
            "user_id": ObjectId(user_id) if isinstance(user_id, str) else user_id,
            "updated_at": datetime.now(timezone.utc),
            "is_deleted": obj_data.get("is_deleted", False)
        })
        
        result = await self.collection.insert_one(obj_data)
        obj_data["_id"] = result.inserted_id
        obj_data["id"] = str(result.inserted_id) 
        return obj_data

    async def get_multi(self, user_id: str, skip: int = 0, limit: int = 100) -> List[dict]:
        query = {
            "user_id": ObjectId(user_id) if isinstance(user_id, str) else user_id,
            "is_deleted": False
        }
        
        cursor = self.collection.find(query).skip(skip).limit(limit)
        results = await cursor.to_list(length=limit)
        
        for doc in results:
            doc["id"] = str(doc.get("_id"))
            if "category_id" in doc and doc["category_id"]:
                doc["category_id"] = str(doc["category_id"])
            if "user_id" in doc:
                doc["user_id"] = str(doc["user_id"])
                
        return results

    async def update_or_create(self, event_id: str, user_id: str, *, obj_in: dict):
        update_data = obj_in.copy()
        update_data["updated_at"] = datetime.now(timezone.utc)
        uid = ObjectId(user_id) if isinstance(user_id, str) else user_id
        update_data["user_id"] = uid
        
        if "_id" in update_data:
            del update_data["_id"]

        query = {"id": event_id, "user_id": uid}
        existing = await self.collection.find_one(query)
        
        if existing:
            await self.collection.update_one(
                {"_id": existing["_id"]},
                {"$set": update_data}
            )
            existing.update(update_data)
            existing["id"] = str(existing["_id"])
            return existing
        else:
            update_data["id"] = event_id 
            result = await self.collection.insert_one(update_data)
            update_data["_id"] = result.inserted_id
            return update_data

    async def mark_as_deleted(self, id: str, user_id: str):
        uid = ObjectId(user_id) if isinstance(user_id, str) else user_id
        
        or_conditions = [{"id": id}]
        
        if ObjectId.is_valid(id):
            or_conditions.append({"_id": ObjectId(id)})
            
        query = {
            "user_id": uid,
            "$or": or_conditions
        }
        
        result = await self.collection.update_one(
            query,
            {"$set": {"is_deleted": True, "updated_at": datetime.now(timezone.utc)}}
        )
        return result.modified_count > 0

event = CRUDEvent("events")