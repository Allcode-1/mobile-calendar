from collections import defaultdict, deque
from dataclasses import dataclass
from threading import Lock
from time import monotonic
from typing import Callable, Deque, Dict, Tuple


@dataclass(frozen=True)
class RateLimitResult:
    allowed: bool
    remaining: int
    retry_after_seconds: int


class InMemoryRateLimiter:
    """Simple fixed-window limiter with per-key timestamps."""

    def __init__(
        self,
        max_requests: int,
        window_seconds: int,
        now_fn: Callable[[], float] | None = None,
    ) -> None:
        if max_requests <= 0:
            raise ValueError("max_requests must be greater than zero")
        if window_seconds <= 0:
            raise ValueError("window_seconds must be greater than zero")

        self._max_requests = max_requests
        self._window_seconds = window_seconds
        self._now = now_fn or monotonic
        self._lock = Lock()
        self._events: Dict[str, Deque[float]] = defaultdict(deque)

    def check(self, key: str) -> RateLimitResult:
        now = self._now()

        with self._lock:
            timestamps = self._events[key]
            cutoff = now - self._window_seconds

            while timestamps and timestamps[0] <= cutoff:
                timestamps.popleft()

            if len(timestamps) >= self._max_requests:
                retry_after = max(1, int(timestamps[0] + self._window_seconds - now))
                return RateLimitResult(
                    allowed=False,
                    remaining=0,
                    retry_after_seconds=retry_after,
                )

            timestamps.append(now)
            remaining = self._max_requests - len(timestamps)
            return RateLimitResult(
                allowed=True,
                remaining=remaining,
                retry_after_seconds=0,
            )
