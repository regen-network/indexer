import logging
from multiprocessing import log_to_stderr
import os
from dotenv import load_dotenv
import sentry_sdk
from index_blocks import index_blocks
from index_retires import index_retires
from index_proposals import index_proposals
from index_class_issuers import index_class_issuers
from index_votes import index_votes
from index_orders import index_orders

load_dotenv()

LOGLEVEL = os.environ.get("LOGLEVEL", logging.INFO)
log_to_stderr(LOGLEVEL)
logging.basicConfig(
    level=LOGLEVEL,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger()


SENTRY_DSN = os.environ.get("SENTRY_DSN")
if SENTRY_DSN:
    logger.debug("initializing sentry..")
    sentry_sdk.init(
        dsn=SENTRY_DSN,
        # Set traces_sample_rate to 1.0 to capture 100%
        # of transactions for performance monitoring.
        # We recommend adjusting this value in production.
        traces_sample_rate=float(os.environ.get("SENTRY_TRACES_SAMPLE_RATE", "0.1")),
        environment=os.environ.get("SENTRY_ENVIRONMENT", "development"),
    )

if __name__ == "__main__":
    index_blocks()
    index_orders()
    index_retires()
    index_proposals()
    index_class_issuers()
    index_votes()
