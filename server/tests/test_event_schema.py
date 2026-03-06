import pytest
from pydantic import ValidationError

from app.schemas.event import EventCreate, EventUpdate


def test_event_create_priority_defaults_to_medium_level():
    event = EventCreate(title="Task")
    assert event.priority == 2


def test_event_create_reminder_defaults_to_none():
    event = EventCreate(title="Task")
    assert event.remind_before is None


def test_event_update_rejects_unknown_fields():
    with pytest.raises(ValidationError):
        EventUpdate.model_validate({"unexpected": "value"})


def test_event_update_accepts_alias_fields():
    patch = EventUpdate.model_validate({"isCompleted": True, "categoryId": "cat-1"})
    data = patch.model_dump(exclude_unset=True, by_alias=False)

    assert data["is_completed"] is True
    assert data["category_id"] == "cat-1"
