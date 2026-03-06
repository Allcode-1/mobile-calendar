from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field
from typing import Optional

class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    color_hex: str = Field(default="#2196F3", pattern="^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$")
    icon: str = Field(default="folder")

class CategoryCreate(CategoryBase):
    id: Optional[str] = Field(default=None, min_length=1)

class CategoryUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: Optional[str] = Field(default=None, min_length=1, max_length=50)
    color_hex: Optional[str] = Field(
        default=None,
        pattern="^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$",
    )
    icon: Optional[str] = None

class CategoryOut(CategoryBase):
    id: str
    user_id: Optional[str] = None
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    is_deleted: bool = False

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)
