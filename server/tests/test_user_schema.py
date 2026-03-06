import pytest
from pydantic import ValidationError

from app.schemas.user import UserCreate


def test_user_create_accepts_strong_password():
    user = UserCreate(
        email="john@example.com",
        password="StrongPass1!",
        full_name="John Doe",
    )
    assert user.email == "john@example.com"


@pytest.mark.parametrize(
    "password",
    [
        "weakpass1!",
        "Weakpass!!",
        "Weakpass11",
    ],
)
def test_user_create_rejects_weak_password(password: str):
    with pytest.raises(ValidationError):
        UserCreate(
            email="john@example.com",
            password=password,
            full_name="John Doe",
        )
