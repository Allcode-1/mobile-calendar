from typing import List, Optional, Any, Dict
from bson import ObjectId
from app.db.mongodb import db_instance
from app.schemas.category import CategoryCreate, CategoryUpdate

class CRUDCategory:
    def __init__(self, collection_name: str):
        self.collection_name = collection_name

    @property
    def collection(self):
        return db_instance.db[self.collection_name]

    async def create(self, user_id: str, obj_in: CategoryCreate) -> Dict:
        obj_dict = obj_in.dict()
        obj_dict["user_id"] = user_id
        
        result = await self.collection.insert_one(obj_dict)
        obj_dict["id"] = str(result.inserted_id)
        if "_id" in obj_dict:
            obj_dict.pop("_id")
        return obj_dict

    async def get_multi(self, user_id: str) -> List[Dict]:
        # get categories of current user
        cursor = self.collection.find({"user_id": user_id})
        categories = await cursor.to_list(length=100)
        
        for cat in categories:
            cat["id"] = str(cat.pop("_id"))
            # if there objectid turn them into str
            for key, value in cat.items():
                if isinstance(value, ObjectId):
                    cat[key] = str(value)
        return categories

    async def update(self, id: str, user_id: str, obj_in: CategoryUpdate) -> Optional[Dict]:
        query = {"_id": ObjectId(id)} if ObjectId.is_valid(id) else {"id": id}
        update_data = {k: v for k, v in obj_in.dict().items() if v is not None}
        
        result = await self.collection.find_one_and_update(
            {"$and": [query, {"user_id": user_id}]},
            {"$set": update_data},
            return_document=True
        )
        if result:
            result["id"] = str(result.pop("_id"))
            return result
        return None

    async def remove(self, id: str, user_id: str) -> bool:
        query = {"_id": ObjectId(id)} if ObjectId.is_valid(id) else {"id": id}
        
        # 1. delete the category
        result = await self.collection.delete_one({"$and": [query, {"user_id": user_id}]})
        
        if result.deleted_count > 0:
            # 2. turn off all tasks categories to null
            await db_instance.db["events"].update_many(
                {"category_id": id, "user_id": user_id},
                {"$set": {"category_id": None}}
            )
            return True
        return False

category = CRUDCategory("categories")