from fastapi import APIRouter
from app.api.v1.endpoints import auth, categories, events, stats

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])
api_router.include_router(categories.router, prefix="/categories", tags=["Categories"])
api_router.include_router(events.router, prefix="/events", tags=["Events"])
api_router.include_router(stats.router, prefix="/stats", tags=["Stats"])