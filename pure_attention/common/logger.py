# !/usr/bin/python
# -*- coding: utf-8 -*-
#
# @author: fly.sun <mmmwhy@mail.ustc.edu.cn>
# @date: 2022/01/24
#
""""""

import logging
import os
import sys

_log_format = "%(asctime)s |- %(levelname).1s %(name)s - %(message)s"


def _get_log_level():
    """ get log level from env variable 'LOG_LEVEL'

    Returns:
        str|int: e.g. "INFO", 20, "DEBUG", 10, "ERROR", 40.

    """
    level = os.environ.get("LOG_LEVEL", "INFO")
    try:
        level = int(level)
    except ValueError:
        assert isinstance(level, str)
        level = level.upper()
    return level


# Attention do not change
# unless you test it online and there is no DEBUG log
# add stream handler to avoid default stream heandler NOSET level
logging.basicConfig(
    format=_log_format,
    level=_get_log_level(),
    stream=sys.stdout)


class LogLevel(object):
    CRITICAL = 50
    ERROR = 40
    WARNING = 30
    INFO = 20
    DEBUG = 10
    DETAIL = 5
    NOTSET = 0


def init_logger(logger_name=None,
                log_file=os.environ.get("LOG_FILE", ""),
                log_format=_log_format,
                level=_get_log_level()):
    """ init logger

    Args:
        logger_name(str): optional, default: None.
        log_file(str): optional, default: "".
            output log messages to file if specified, by default is set by env
            `LOG_FILE`.
        log_format(str): optional, default:
            "%(asctime)s |- %(levelname).1s %(name)s - %(message)s"
        level(int|logging.Level): set log level, by default it is set by env
            `LOG_LEVEL`, `INFO` level is used if not set.
        :: level
            - CRITICAL    50
            - ERROR	40
            - WARNING	30
            - INFO	20
            - DEBUG	10
            - DETAIL  5
            - NOTSET  0

    Returns:
        logging.Logger: a logger instance

    """
    logger = logging.getLogger(logger_name)
    logger.setLevel(level)

    if log_file:
        handler = logging.FileHandler(log_file)
        if log_format:
            formatter = logging.Formatter(log_format)
            handler.setFormatter(formatter)

        logger.addHandler(handler)

    return logger


def _test():
    logger = init_logger("test_logger", "test_file.log",
                         level=_get_log_level())
    logger.info("level: {}".format(os.environ.get("LOG_LEVEL", "INFO")))
    import sys
    logger.info(sys.modules[__name__])
    logger.info(logging.getLoggerClass())
    logger.debug("test DEBUG 10")
    logger.info("test INFO 20")
    logger.warning("test WARNING 30")
    logger.error("test ERROR 40")
    logger.critical("test CRITICAL 50")

    if logger.isEnabledFor(logging.DEBUG):
        logger.warning("debug enabled!")
    if logger.isEnabledFor(LogLevel.DEBUG):
        logger.info("detail enabled")


if __name__ == "__main__":
    _test()
