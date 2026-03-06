from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query
from app.api.v1.endpoints.auth import get_current_user
from app.crud.crud_category import category as crud_category
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate

router = APIRouter()

@router.post("/", response_model=CategoryOut)
async def create_category(obj_in: CategoryCreate, current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    return await crud_category.create(user_id=user_id, obj_in=obj_in)

@router.get("/", response_model=List[CategoryOut])
async def read_categories(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=500),
    include_deleted: bool = Query(default=False),
    current_user=Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    return await crud_category.get_multi(
        user_id=user_id,
        skip=skip,
        limit=limit,
        include_deleted=include_deleted,
    )

@router.patch("/{id}", response_model=CategoryOut)
async def update_category(id: str, obj_in: CategoryUpdate, current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    updated = await crud_category.update(id=id, user_id=user_id, obj_in=obj_in)
    if not updated:
        raise HTTPException(status_code=404, detail="Category not found")
    return updated

@router.delete("/{id}")
async def delete_category(id: str, current_user=Depends(get_current_user)):
    user_id = str(current_user["_id"])
    success = await crud_category.remove(id=id, user_id=user_id)
    if not success:
        raise HTTPException(status_code=404, detail="Category not found")
    return {"status": "success"}
