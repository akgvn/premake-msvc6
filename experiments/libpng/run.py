#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Generate the libpng workspace and structurally diff it against the original.

Generates into a shadow tree (libpng/ + sibling zlib/, mirroring the real
cross-tree reference) and structurally diffs against the real-world
originals (real-world-test-cases/libpng) via tools/dspdiff.py.

Usage: uv run experiments/libpng/run.py [path-to-premake5]
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
        description="Generate the libpng workspace and structurally diff it.",
    )
    parser.add_argument(
        "premake5",
        nargs="?",
        help="path to premake5 (default: $PREMAKE5, .deps, PATH)",
    )
    args = parser.parse_args()

    binary = require_premake5(args.premake5)
    real = REPO / "real-world-test-cases" / "libpng"

    work = EXP / "build"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    project_dir = work / "libpng" / "projects" / "visualc6"
    project_dir.mkdir(parents=True)
    shutil.copy(EXP / "premake5.lua", project_dir / "premake5.lua")

    generate(binary, project_dir)

    status = run_dspdiff(
        [
            (real / "libpng.dsw", project_dir / "libpng.dsw"),
            (real / "libpng.dsp", project_dir / "libpng.dsp"),
            (real / "pngtest.dsp", project_dir / "pngtest.dsp"),
        ]
    )

    if status == 0:
        print("libpng experiment: all files structurally match")
    else:
        print("libpng experiment: structural differences above")
    return status


if __name__ == "__main__":
    sys.exit(main())
