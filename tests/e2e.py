#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""End-to-end regression check of the vs6 module against tests/golden/.

Runs the module on samples/premake5.lua and diffs the generated files
against the committed golden baseline with a normalized diff: path
separators (the module emits backslashes) and line endings (the goldens
are CRLF) are canonicalized; everything else must match byte-for-byte.

Usage: uv run tests/e2e.py [path-to-premake5]
The binary defaults to $PREMAKE5, the pinned .deps/ download
(tools/premake5.py), or premake5 on PATH.
"""

import argparse
import difflib
import shutil
import sys
import tempfile
from pathlib import Path
from typing import List

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from premake5lib import generate, require_premake5

FILES = ["Sample.dsw", "app.dsp", "core.dsp", "engine.dsp", "tool.dsp"]


def normalize(path: Path) -> List[str]:
    """Read a generated/golden file, canonicalized for comparison."""
    text = path.read_text(encoding="utf-8", errors="replace")
    return [line.replace("\\", "/") for line in text.splitlines()]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Diff generated sample output against tests/golden/.",
    )
    parser.add_argument(
        "premake5",
        nargs="?",
        help="path to premake5 (default: $PREMAKE5, .deps, PATH)",
    )
    args = parser.parse_args()

    binary = require_premake5(args.premake5)
    status = 0

    with tempfile.TemporaryDirectory(prefix="vs6-e2e-") as tmp:
        work = Path(tmp)
        shutil.copy(REPO / "samples" / "premake5.lua", work / "premake5.lua")
        generate(binary, work)

        for name in FILES:
            generated = work / name
            golden = REPO / "tests" / "golden" / name
            if not generated.is_file():
                print(f"{name}: NOT GENERATED")
                status = 1
            elif normalize(generated) == normalize(golden):
                print(f"{name}: OK")
            else:
                print(f"{name}: DIFFERS")
                diff = difflib.unified_diff(
                    normalize(golden),
                    normalize(generated),
                    fromfile=str(golden),
                    tofile=str(generated),
                    lineterm="",
                )
                print("\n".join(diff))
                status = 1

    if status == 0:
        print("E2E: all files match the golden baseline (normalized)")
    else:
        print("E2E: FAILED")
    return status


if __name__ == "__main__":
    sys.exit(main())
