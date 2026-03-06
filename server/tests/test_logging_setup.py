import logging

from app.core.logging import InterceptHandler, setup_logging


def test_setup_logging_installs_intercept_handler():
    setup_logging()
    root_handlers = logging.getLogger().handlers

    assert root_handlers
    assert any(isinstance(handler, InterceptHandler) for handler in root_handlers)
