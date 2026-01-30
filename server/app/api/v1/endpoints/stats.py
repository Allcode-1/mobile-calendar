from fastapi import APIRouter, Depends
from app.api.v1.endpoints.auth import get_current_user
from app.db.mongodb import db_instance

router = APIRouter()

@router.get("/summary")
async def get_summary(current_user=Depends(get_current_user)):
    """analise user's events and return stats"""
    events_col = db_instance.db["events"]
    u_id = current_user["id"]

    # count total and completed events
    total = await events_col.count_documents({"user_id": u_id, "is_deleted": False})
    completed = await events_col.count_documents({
        "user_id": u_id, 
        "is_completed": True, 
        "is_deleted": False
    })

    # group by category using pipeline
    pipeline = [
        {"$match": {"user_id": u_id, "is_deleted": False}},
        {"$group": {"_id": "$category_id", "count": {"$sum": 1}}}
    ]
    
    cat_stats = []
    async for item in events_col.aggregate(pipeline):
        cat_stats.append({"category_id": item["_id"], "count": item["count"]})

    return {
        "total": total,
        "completed": completed,
        "completion_rate": round((completed / total * 100), 2) if total > 0 else 0,
        "by_category": cat_stats
    }