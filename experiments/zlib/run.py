#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Generate the zlib workspace and structurally diff it against the original.

Generates into a shadow tree (experiments/zlib/build/, gitignored) and
structurally diffs each file against real-world-test-cases/zlib via
tools/dspdiff.py.

Usage: uv run experiments/zlib/run.py [path-to-premake5]
"""

import argparse
import shutil
import sys
from pathlib import Path

EXP = Path(__file__).resolve().parent
REPO = EXP.parents[1]
sys.path.insert(0, str(REPO / "tools"))

from premake5lib import generate, require_premake5, run_dspdiff


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate the zlib workspace and structurally diff it.",
    )
    parser.add_argument(
        "premake5",
        nargs="?",
        help="path to premake5 (default: $PREMAKE5, .deps, PATH)",
    )
    args = parser.parse_args()

    binary = require_premake5(args.premake5)
    real = REPO / "real-world-test-cases" / "zlib"

    work = EXP / "build"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    project_dir = work / "projects" / "visualc6"
    project_dir.mkdir(parents=True)
    shutil.copy(EXP / "premake5.lua", project_dir / "premake5.lua")

    generate(binary, project_dir)

    status = run_dspdiff(
        [
            (real / "zlib.dsw", project_dir / "zlib.dsw"),
            (real / "zlib.dsp", project_dir / "zlib.dsp"),
            (real / "example.dsp", project_dir / "example.dsp"),
            (real / "minigzip.dsp", project_dir / "minigzip.dsp"),
        ]
    )

    if status == 0:
        print("zlib experiment: all files structurally match")
    else:
        print("zlib experiment: structural differences above")
    return status


if __name__ == "__main__":
    sys.exit(main())
