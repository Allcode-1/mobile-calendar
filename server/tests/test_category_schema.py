import pytest
from pydantic import ValidationError

from app.schemas.category import CategoryCreate, CategoryUpdate


def test_category_create_accepts_custom_id():
    category = CategoryCreate(id="cat-local-1", name="Work")
    assert category.id == "cat-local-1"


def test_category_update_rejects_unknown_field():
    with pytest.raises(ValidationError):
        CategoryUpdate.model_validate({"unexpected": "value"})
