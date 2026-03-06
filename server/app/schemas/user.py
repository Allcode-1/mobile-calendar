import re
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from typing import Optional
from datetime import datetime

class UserProfile(BaseModel):
    full_name: str
    avatar_url: Optional[str] = None
    timezone: str = "UTC"

class UserCreate(BaseModel):
    email: EmailStr
    # minimum 8 symbols for password
    password: str = Field(..., min_length=8)
    full_name: str = Field(..., min_length=2)

    @field_validator('password')
    @classmethod
    def password_complexity(cls, v: str) -> str:
        # check for uppercase
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        
        # check for special symbol
        if not re.search(r'[!@#$%^&*(),.?":{}|<>+=\-_]', v):
            raise ValueError('Password must contain at least one special character')
            
        # check for number
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one digit')
            
        return v

class UserOut(BaseModel):
    id: str
    email: EmailStr
    profile: UserProfile
    created_at: datetime = Field(default_factory=datetime.utcnow)

    model_config = ConfigDict(from_attributes=True)
