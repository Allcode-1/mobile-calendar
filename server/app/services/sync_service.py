from typing import List
from app.crud.crud_event import event as crud_event
from app.schemas.event import EventSync 
from datetime import datetime, timezone
from bson import ObjectId

class SyncService:
    async def sync_user_events(self, user_id: str, client_events: List[EventSync]) -> List[dict]:
        """
        sync logic:
        1. check every event from client
        2. if event is not in db or newer - create or update
        3. return all events from db formatted for Pydantic
        """
        for client_event in client_events:
            client_data = client_event.model_dump()
            event_id = client_data.get("id")
            
            existing = await crud_event.get(event_id, user_id)
            
            if not client_data.get("updated_at"):
                client_data["updated_at"] = datetime.now(timezone.utc)
            elif client_data["updated_at"].tzinfo is None:
                client_data["updated_at"] = client_data["updated_at"].replace(tzinfo=timezone.utc)

            should_update = False
            if not existing:
                should_update = True
            else:
                db_updated_at = existing.get("updated_at")
                if db_updated_at and db_updated_at.tzinfo is None:
                    db_updated_at = db_updated_at.replace(tzinfo=timezone.utc)
                
                if not db_updated_at or client_data["updated_at"] > db_updated_at:
                    should_update = True

            if should_update:
                update_data = client_data.copy()
                
                if update_data.get("category_id"):
                    try:
                        update_data["category_id"] = ObjectId(update_data["category_id"])
                    except:
                        pass 
                
                await crud_event.update_or_create(
                    event_id=event_id, 
                    user_id=user_id, 
                    obj_in=update_data
                )
        
        raw_events = await crud_event.get_multi(user_id)
        
        final_events = []
        for event in raw_events:
            event_dict = dict(event)
            if "_id" in event_dict:
                event_dict["id"] = str(event_dict["_id"])
            if "category_id" in event_dict:
                event_dict["category_id"] = str(event_dict["category_id"])
            if "user_id" in event_dict:
                event_dict["user_id"] = str(event_dict["user_id"])
                
            final_events.append(event_dict)

        return final_events

sync_service = SyncService()