import time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from uuid import uuid4

from app.core.logging import logger

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # check start time
        start_time = time.time()
        request_id = request.headers.get("x-request-id") or str(uuid4())
        
        # run request
        response = await call_next(request)
        
        # count time for process
        process_time = (time.time() - start_time) * 1000
        formatted_process_time = f"{process_time:.2f}ms"
        
        logger.bind(request_id=request_id, scope="http").info(
            "method={} path={} status={} duration_ms={:.2f}",
            request.method,
            request.url.path,
            response.status_code,
            process_time,
        )
        
        # add time info into log headers
        response.headers["X-Process-Time"] = formatted_process_time
        response.headers["X-Request-ID"] = request_id
        
        return response
