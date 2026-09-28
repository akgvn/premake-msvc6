#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Generate the Peter workspace and structurally diff it against the original.

Generates into a shadow tree (experiments/peter/build/, gitignored) and
structurally diffs each file against real-world-test-cases/peter via
tools/dspdiff.py.

Usage: uv run experiments/peter/run.py [path-to-premake5]
"""

import argparse
import os
import re
import shutil
import sys
from pathlib import Path

EXP = Path(__file__).resolve().parent
REPO = EXP.parents[1]
sys.path.insert(0, str(REPO / "tools"))

from premake5lib import generate, require_premake5, run_dspdiff

SOURCE_LINE = re.compile(r'^SOURCE="?([^"\r\n]+)"?', re.M)


def materialize_sources(real: Path, work: Path) -> None:
    """Create empty placeholders for every SOURCE= path in the real .dsp files.

    premake5's file globbing only matches existing files. The originals
    reference sources from the project tree, so recreate their paths as
    empty files in the shadow tree.
    """
    for dsp in real.rglob("*"):
        if dsp.suffix.lower() != ".dsp":
            continue
        text = dsp.read_text(encoding="latin-1")
        project_dir = dsp.parent.relative_to(real)
        for match in SOURCE_LINE.finditer(text):
            source = match.group(1).replace("\\", "/")
            if source.startswith("./"):
                source = source[2:]
            target = Path(os.path.normpath(str(work / project_dir / source)))
            target.parent.mkdir(parents=True, exist_ok=True)
            target.touch(exist_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate the Peter workspace and structurally diff it.",
    )
    parser.add_argument(
        "premake5",
        nargs="?",
        help="path to premake5 (default: $PREMAKE5, .deps, PATH)",
    )
    args = parser.parse_args()

    binary = require_premake5(args.premake5)
    real = REPO / "real-world-test-cases" / "peter"

    work = EXP / "build"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    shutil.copy(EXP / "premake5.lua", work / "premake5.lua")

    materialize_sources(real, work)
    generate(binary, work)

    status = run_dspdiff(
        [
            (real / "Peter.dsw", work / "Peter.dsw"),
            (real / "Peter.dsp", work / "Peter.dsp"),
            (real / "DataInst/DataInst.dsp", work / "DataInst/DataInst.dsp"),
            (real / "DelExe/DelExe.dsp", work / "DelExe/DelExe.dsp"),
            (real / "Gener/Gener.dsp", work / "Gener/Gener.dsp"),
            (real / "Loader/Peter.dsp", work / "Loader/Peter.dsp"),
            (real / "Loader0/Peter.dsp", work / "Loader0/Peter.dsp"),
            (real / "Pov2Spr/Pov2Spr.dsp", work / "Pov2Spr/Pov2Spr.dsp"),
            (real / "Setup/Setup.dsp", work / "Setup/Setup.dsp"),
        ]
    )

    if status == 0:
        print("peter experiment: all files structurally match")
    else:
        print("peter experiment: structural differences above")
    return status


if __name__ == "__main__":
    sys.exit(main())
