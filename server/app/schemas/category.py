from pydantic import BaseModel, Field
from typing import Optional

class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    color_hex: str = Field(default="#2196F3", pattern="^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$")
    icon: str = Field(default="folder")

class CategoryCreate(CategoryBase):
    pass 

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    color_hex: Optional[str] = None
    icon: Optional[str] = None

class CategoryOut(CategoryBase):
    id: str

    class Config:
        from_attributes = True
        populate_by_name = True