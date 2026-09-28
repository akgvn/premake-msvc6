#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Run the vs6 unit tests through premake5's embedded self-test harness.

Run tools/premake5.py once to fetch the pinned binary, or point $PREMAKE5
at a matching premake5 install.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from premake5lib import require_premake5, run_suites


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run the vs6 unit tests (premake5 self-test harness).",
    )
    parser.add_argument(
        "pattern",
        nargs="?",
        default="vs6*",
        help="--test-only value (default: %(default)s); '*' runs every suite",
    )
    args = parser.parse_args()

    return run_suites(require_premake5(), args.pattern)


if __name__ == "__main__":
    sys.exit(main())
