from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings
from app.core.logging import logger


class Database:
    client: AsyncIOMotorClient = None
    db = None

db_instance = Database()

async def connect_to_mongo():
    db_instance.client = AsyncIOMotorClient(settings.MONGODB_URL)
    db_instance.db = db_instance.client[settings.DATABASE_NAME]

    # Indexes reduce query latency for user-scoped sync and CRUD operations.
    await db_instance.db["events"].create_index(
        [("user_id", 1), ("id", 1)],
        unique=True,
        sparse=True,
    )
    await db_instance.db["events"].create_index([("user_id", 1), ("updated_at", -1)])
    await db_instance.db["events"].create_index([("user_id", 1), ("is_deleted", 1)])
    await db_instance.db["categories"].create_index(
        [("user_id", 1), ("id", 1)],
        unique=True,
        sparse=True,
    )
    await db_instance.db["categories"].create_index([("user_id", 1), ("name", 1)])

    logger.info("Connected to MongoDB")

async def close_mongo_connection():
    db_instance.client.close()
    logger.info("MongoDB connection closed")
