from datetime import timedelta, datetime
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import jwt, JWTError
from app.core import security
from app.core.config import settings
from app.db.mongodb import db_instance
from app.schemas.user import UserCreate, UserOut
from app.schemas.token import Token, TokenData
from bson import ObjectId

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        token_data = TokenData(email=user_id)
    except JWTError:
        raise credentials_exception
        
    user = await db_instance.db["users"].find_one({"_id": ObjectId(user_id)})
    if user is None:
        raise credentials_exception
    
    user["id"] = str(user["_id"])
    return user

@router.post("/register", response_model=UserOut)
async def register(user_in: UserCreate):
    user_exists = await db_instance.db["users"].find_one({"email": user_in.email})
    if user_exists:
        raise HTTPException(status_code=400, detail="User already exists")
    
    user_dict = user_in.dict()
    user_dict["hashed_password"] = security.get_password_hash(user_dict.pop("password"))
    user_dict["profile"] = {"full_name": user_in.full_name}
    
    result = await db_instance.db["users"].insert_one(user_dict)
    user_id_str = str(result.inserted_id)
    user_dict["id"] = user_id_str
    
    # 2. seeding of categories (auto generating of def cats)
    default_categories = [
        {"name": "Home", "color_hex": "#4CAF50", "icon": "home"},
        {"name": "Work", "color_hex": "#F44336", "icon": "work"},
        {"name": "Study", "color_hex": "#2196F3", "icon": "school"},
    ]
    
    try:
        for cat in default_categories:
            cat["user_id"] = user_id_str
        
        # insert in categories
        await db_instance.db["categories"].insert_many(default_categories)
        print(f"--- LOG: Created default categories for user {user_id_str} ---")
    except Exception as e:
        # dont stop registrating if error with categories
        print(f"!!! Error seeding categories for {user_id_str}: {e}")

    return user_dict

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = await db_instance.db["users"].find_one({"email": form_data.username})
    if not user or not security.verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    # create token using str id of user
    access_token = security.create_access_token(subject=str(user["_id"]))
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserOut)
async def read_users_me(current_user=Depends(get_current_user)):
    return current_user