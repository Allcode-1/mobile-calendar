import pytest

from app.core.config import Settings


def test_settings_parse_cors_and_rate_paths_from_csv():
    settings = Settings(
        MONGODB_URL="mongodb://localhost:27017",
        SECRET_KEY="A" * 40,
        BACKEND_CORS_ORIGINS="http://a.local,http://b.local",
        RATE_LIMIT_PATHS="/a,/b",
        RATE_LIMIT_METHODS="post,patch",
    )

    assert settings.BACKEND_CORS_ORIGINS == ["http://a.local", "http://b.local"]
    assert settings.RATE_LIMIT_PATHS == ["/a", "/b"]
    assert settings.RATE_LIMIT_METHODS == ["POST", "PATCH"]


def test_settings_rejects_short_secret():
    with pytest.raises(ValueError):
        Settings(
            MONGODB_URL="mongodb://localhost:27017",
            SECRET_KEY="short-secret",
        )


def test_settings_parses_proxy_header_flag():
    settings = Settings(
        MONGODB_URL="mongodb://localhost:27017",
        SECRET_KEY="A" * 40,
        TRUST_PROXY_HEADERS=True,
    )
    assert settings.TRUST_PROXY_HEADERS is True
