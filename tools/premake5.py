#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Prepare the pinned premake5 binary and run the vs6 unit tests.

Release binaries ship the Lua core and the self-test harness, so no
premake-core checkout, compiler, or Bootstrap is needed:

  1. use an installed premake5 if its version matches the pinned tag
  2. otherwise download the official release archive into .deps/premake5/
  3. run the vs6 unit tests via tools/test.py
"""

import argparse
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from premake5lib import DEPS, DEFAULT_TAG, ensure_binary, run_suites


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Prepare the pinned premake5 binary and run the vs6 unit tests.",
    )
    parser.add_argument(
        "--tag",
        default=DEFAULT_TAG,
        help="premake5 release tag (default: %(default)s)",
    )
    parser.add_argument(
        "--no-test",
        action="store_true",
        help="skip the unit test run",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="remove .deps/",
    )
    args = parser.parse_args()

    if args.clean:
        shutil.rmtree(DEPS, ignore_errors=True)
        print(f"premake5: removed {DEPS}")
        return 0

    binary = ensure_binary(args.tag)
    if args.no_test:
        print(f"premake5: ready ({binary})")
        return 0

    print("premake5: running vs6 unit tests")
    return run_suites(binary)


if __name__ == "__main__":
    sys.exit(main())
