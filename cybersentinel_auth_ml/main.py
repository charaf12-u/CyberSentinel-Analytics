from __future__ import annotations
import logging
import sys
import time
from cybersentinel_auth_ml.pipeline import run_pipeline


LOGGER = logging.getLogger("cybersentinel_auth_ml")

# --> Logging configuration function
def configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format=(
            "%(asctime)s | "
            "%(levelname)s | "
            "%(name)s | "
            "%(message)s"
        ),
        force=True,
    )

# --> Main function
def main() -> None:
    configure_logging()

    LOGGER.info("=" * 70)
    LOGGER.info("CyberSentinel Authentication ML Pipeline Started")
    LOGGER.info("=" * 70)
    start_time = time.perf_counter()

    try:
        results = run_pipeline()
        execution_time = time.perf_counter() - start_time
        LOGGER.info("Authentication ML pipeline completed successfully.")
        LOGGER.info("Authentication windows processed: %d",len(results))
        LOGGER.info("Execution time: %.2f seconds",execution_time)
        LOGGER.info("=" * 70)

    except KeyboardInterrupt:
        LOGGER.warning("Authentication ML pipeline interrupted by user.")
        sys.exit(130)

    except Exception:
        LOGGER.exception("Authentication ML pipeline failed.")
        sys.exit(1)


if __name__ == "__main__":
    main()