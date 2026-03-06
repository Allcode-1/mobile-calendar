import pytest
from jose import jwt

from app.core.config import settings
from app.core.security import ALGORITHM, create_access_token, get_password_hash, verify_password


def test_password_hash_and_verify():
    plain = "StrongPass1!"
    try:
        hashed = get_password_hash(plain)
    except ValueError as exc:
        # Some local Python/bcrypt combos (notably 3.14) are not supported by passlib bcrypt backend.
        pytest.skip(f"bcrypt backend unavailable in current environment: {exc}")

    assert hashed != plain
    assert verify_password(plain, hashed) is True
    assert verify_password("WrongPass1!", hashed) is False


def test_create_access_token_contains_subject():
    token = create_access_token("user-123")
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])

    assert payload["sub"] == "user-123"
    assert "exp" in payload
