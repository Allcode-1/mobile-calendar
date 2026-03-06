from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

from app.core.config import settings
from app.core.rate_limiter import InMemoryRateLimiter


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app) -> None:
        super().__init__(app)
        self._limiter = InMemoryRateLimiter(
            max_requests=settings.RATE_LIMIT_REQUESTS,
            window_seconds=settings.RATE_LIMIT_WINDOW_SECONDS,
        )
        self._paths = tuple(settings.RATE_LIMIT_PATHS)
        self._methods = set(settings.RATE_LIMIT_METHODS)
        self._trust_proxy_headers = settings.TRUST_PROXY_HEADERS

    def _client_identifier(self, request: Request) -> str:
        if self._trust_proxy_headers:
            forwarded = request.headers.get("x-forwarded-for")
            if forwarded:
                return forwarded.split(",")[0].strip()

            real_ip = request.headers.get("x-real-ip")
            if real_ip:
                return real_ip.strip()

        if request.client and request.client.host:
            return request.client.host
        return "unknown"

    @staticmethod
    def _matches_path(path: str, pattern: str) -> bool:
        if pattern.endswith("*"):
            return path.startswith(pattern[:-1])
        return path == pattern

    def _is_limited_request(self, request: Request) -> bool:
        if self._methods and request.method.upper() not in self._methods:
            return False
        for pattern in self._paths:
            if self._matches_path(request.url.path, pattern):
                return True
        return False

    async def dispatch(self, request: Request, call_next):
        if self._is_limited_request(request):
            client_id = self._client_identifier(request)
            key = f"{request.url.path}:{client_id}"
            result = self._limiter.check(key)

            if not result.allowed:
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Too many requests. Please try again later."},
                    headers={"Retry-After": str(result.retry_after_seconds)},
                )

        response = await call_next(request)
        return response
