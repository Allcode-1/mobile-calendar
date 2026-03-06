from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import Optional, List

class EventBase(BaseModel):
    title: str
    description: Optional[str] = None
    category_id: Optional[str] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    remind_before: Optional[int] = Field(default=None, ge=0)
    is_completed: bool = False
    priority: int = Field(default=2, ge=1, le=3)
    is_deleted: bool = False

class EventCreate(EventBase):
    id: Optional[str] = Field(default=None, min_length=1)


class EventUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    title: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[str] = Field(default=None, alias="categoryId")
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    remind_before: Optional[int] = Field(default=None, ge=0)
    is_completed: Optional[bool] = Field(default=None, alias="isCompleted")
    priority: Optional[int] = Field(default=None, ge=1, le=3)
    is_deleted: Optional[bool] = None

class EventOut(EventBase):
    id: str
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    model_config = ConfigDict(from_attributes=True)

class EventSync(EventBase):
    id: str  
    updated_at: Optional[datetime] = None

class SyncSchema(BaseModel):
    events: List[EventSync]
