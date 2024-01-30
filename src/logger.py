import logging

from pythonjsonlogger import jsonlogger

logger = logging.getLogger("my_logger")
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter(  # type: ignore
    "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
handler.setFormatter(formatter)
logger.addHandler(handler)
