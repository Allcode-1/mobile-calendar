from app.core.rate_limiter import InMemoryRateLimiter


def test_rate_limiter_blocks_after_limit():
    now = 1000.0

    def now_fn() -> float:
        return now

    limiter = InMemoryRateLimiter(max_requests=2, window_seconds=60, now_fn=now_fn)

    first = limiter.check("ip-1")
    second = limiter.check("ip-1")
    third = limiter.check("ip-1")

    assert first.allowed is True
    assert second.allowed is True
    assert third.allowed is False
    assert third.retry_after_seconds > 0


def test_rate_limiter_unblocks_after_window():
    now_box = {"value": 1000.0}

    def now_fn() -> float:
        return now_box["value"]

    limiter = InMemoryRateLimiter(max_requests=1, window_seconds=10, now_fn=now_fn)

    assert limiter.check("ip-1").allowed is True
    assert limiter.check("ip-1").allowed is False

    now_box["value"] += 11

    assert limiter.check("ip-1").allowed is True
