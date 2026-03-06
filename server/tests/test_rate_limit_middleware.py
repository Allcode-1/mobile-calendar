from app.middleware.rate_limit import RateLimitMiddleware
from starlette.requests import Request


async def _dummy_app(scope, receive, send):
    return None


def _make_request(method: str, path: str, headers=None, client=("127.0.0.1", 12345)):
    scope = {
        "type": "http",
        "asgi": {"version": "3.0"},
        "http_version": "1.1",
        "method": method,
        "scheme": "http",
        "path": path,
        "raw_path": path.encode(),
        "query_string": b"",
        "headers": headers or [],
        "client": client,
        "server": ("testserver", 80),
        "root_path": "",
    }
    return Request(scope)


def test_rate_limit_path_exact_match():
    assert RateLimitMiddleware._matches_path("/api/v1/auth/login", "/api/v1/auth/login")
    assert not RateLimitMiddleware._matches_path(
        "/api/v1/auth/login/extra", "/api/v1/auth/login"
    )


def test_rate_limit_path_wildcard_match():
    assert RateLimitMiddleware._matches_path("/api/v1/events/123", "/api/v1/events/*")
    assert RateLimitMiddleware._matches_path("/api/v1/events/", "/api/v1/events/*")
    assert not RateLimitMiddleware._matches_path("/api/v1/stats/summary", "/api/v1/events/*")


def test_rate_limit_respects_method_and_path_patterns():
    middleware = RateLimitMiddleware(_dummy_app)
    middleware._paths = ("/api/v1/events/*",)
    middleware._methods = {"PATCH"}

    patch_request = _make_request("PATCH", "/api/v1/events/abc")
    get_request = _make_request("GET", "/api/v1/events/abc")

    assert middleware._is_limited_request(patch_request) is True
    assert middleware._is_limited_request(get_request) is False


def test_client_identifier_prefers_proxy_headers_only_when_enabled():
    middleware = RateLimitMiddleware(_dummy_app)
    request = _make_request(
        "POST",
        "/api/v1/auth/login",
        headers=[(b"x-forwarded-for", b"203.0.113.10"), (b"x-real-ip", b"203.0.113.20")],
        client=("127.0.0.1", 9000),
    )

    middleware._trust_proxy_headers = False
    assert middleware._client_identifier(request) == "127.0.0.1"

    middleware._trust_proxy_headers = True
    assert middleware._client_identifier(request) == "203.0.113.10"
