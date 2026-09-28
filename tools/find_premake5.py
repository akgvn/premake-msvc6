#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Print the premake5 binary the repository's scripts would use.

Resolution order: an explicit path argument, $PREMAKE5, the pinned
.deps/premake5 download (tools/premake5.py), then premake5 on PATH.
Exits 1 when nothing is found.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from premake5lib import find_premake5


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Print the premake5 binary the repo scripts would use.",
    )
    parser.add_argument("binary", nargs="?", help="explicit path to use")
    args = parser.parse_args()

    binary = find_premake5(args.binary)
    if binary is None:
        print(
            "find_premake5: no premake5 found; run 'uv run tools/premake5.py' first",
            file=sys.stderr,
        )
        return 1
    print(binary)
    return 0


if __name__ == "__main__":
    sys.exit(main())
