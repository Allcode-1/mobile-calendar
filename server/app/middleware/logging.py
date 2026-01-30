import time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # check start time
        start_time = time.time()
        
        # run request
        response = await call_next(request)
        
        # count time for process
        process_time = (time.time() - start_time) * 1000
        formatted_process_time = f"{process_time:.2f}ms"
        
        # log for terminal
        print(
            f"LOG: {request.method} {request.url.path} "
            f"| Status: {response.status_code} "
            f"| Time: {formatted_process_time}"
        )
        
        # add time info into log headers
        response.headers["X-Process-Time"] = formatted_process_time
        
        return response