#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Generate the Quake 2 workspace and structurally diff it against the original.

Generates into a shadow tree (experiments/quake2/build/, gitignored) and
structurally diffs each file against real-world-test-cases/quake2 via
tools/dspdiff.py.

Usage: uv run experiments/quake2/run.py [path-to-premake5]
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
        description="Generate the Quake 2 workspace and structurally diff it.",
    )
    parser.add_argument(
        "premake5",
        nargs="?",
        help="path to premake5 (default: $PREMAKE5, .deps, PATH)",
    )
    args = parser.parse_args()

    binary = require_premake5(args.premake5)
    real = REPO / "real-world-test-cases" / "quake2"

    work = EXP / "build" / "quake2"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    shutil.copy(EXP / "premake5.lua", work / "premake5.lua")

    generate(binary, work)

    status = run_dspdiff(
        [
            (real / "quake2.dsw", work / "quake2.dsw"),
            (real / "quake2.dsp", work / "quake2.dsp"),
            (real / "ctf/ctf.dsp", work / "ctf/ctf.dsp"),
            (real / "game/game.dsp", work / "game/game.dsp"),
            (real / "ref_gl/ref_gl.dsp", work / "ref_gl/ref_gl.dsp"),
            (real / "ref_soft/ref_soft.dsp", work / "ref_soft/ref_soft.dsp"),
        ]
    )

    if status == 0:
        print("quake2 experiment: all files structurally match")
    else:
        print("quake2 experiment: structural differences above")
    return status


if __name__ == "__main__":
    sys.exit(main())
