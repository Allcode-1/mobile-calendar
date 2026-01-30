from typing import Any, Generic, List, Optional, Type, TypeVar, Union
from bson import ObjectId
from pydantic import BaseModel
from app.db.mongodb import db_instance

ModelType = TypeVar("ModelType", bound=BaseModel)
CreateSchemaType = TypeVar("CreateSchemaType", bound=BaseModel)
UpdateSchemaType = TypeVar("UpdateSchemaType", bound=BaseModel)

class CRUDBase(Generic[ModelType, CreateSchemaType, UpdateSchemaType]):
    def __init__(self, collection_name: str):
        self.collection_name = collection_name

    @property
    def collection(self):
        return db_instance.db[self.collection_name]

    async def get(self, id: str, user_id: str) -> Optional[ModelType]:
        if not ObjectId.is_valid(id):
            return None
        doc = await self.collection.find_one({"_id": ObjectId(id), "user_id": user_id})
        if doc:
            doc["id"] = str(doc.pop("_id"))
            return doc
        return None

    async def get_multi(
        self, user_id: str, *, skip: int = 0, limit: int = 100
    ) -> List[ModelType]:
        cursor = self.collection.find({"user_id": user_id}).skip(skip).limit(limit)
        results = []
        async for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            results.append(doc)
        return results

    async def create(self, user_id: str, *, obj_in: CreateSchemaType) -> ModelType:
        obj_in_data = obj_in.model_dump()
        obj_in_data["user_id"] = user_id
        result = await self.collection.insert_one(obj_in_data)
        obj_in_data["id"] = str(result.inserted_id)
        return obj_in_data

    async def update(
        self, id: str, user_id: str, *, obj_in: Union[UpdateSchemaType, dict]
    ) -> Optional[ModelType]:
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.model_dump(exclude_unset=True)
            
        result = await self.collection.find_one_and_update(
            {"_id": ObjectId(id), "user_id": user_id},
            {"$set": update_data},
            return_document=True
        )
        if result:
            result["id"] = str(result.pop("_id"))
            return result
        return None

    async def remove(self, id: str, user_id: str) -> bool:
        result = await self.collection.delete_one({"_id": ObjectId(id), "user_id": user_id})
        return result.deleted_count > 0