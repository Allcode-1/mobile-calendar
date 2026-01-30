from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

class EventBase(BaseModel):
    title: str
    description: Optional[str] = None
    category_id: Optional[str] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    remind_before: int = 15
    is_completed: bool = False
    priority: int = Field(default=2, ge=1, le=3)
    is_deleted: bool = False

class EventCreate(EventBase):
    pass

class EventOut(EventBase):
    id: str
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        from_attributes = True

class EventSync(EventBase):
    id: str  
    updated_at: Optional[datetime] = None

class SyncSchema(BaseModel):
    events: List[EventSync]