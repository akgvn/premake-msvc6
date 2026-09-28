#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Generate the Windows acceptance projects.

Produces tests/acceptance/build/ containing vc6_acceptance.dsw, one .dsp
per profile, the trivial sources, and manifest.txt (the list the Windows
harness iterates). Safe to regenerate; build/ is gitignored.

Usage: uv run tests/acceptance/generate.py [path-to-premake5]
The binary defaults to $PREMAKE5, the pinned .deps/ download
(tools/premake5.py), or premake5 on PATH.
"""

import argparse
import shutil
import sys
from pathlib import Path

ACC = Path(__file__).resolve().parent
REPO = ACC.parents[1]
sys.path.insert(0, str(REPO / "tools"))

from premake5lib import generate, require_premake5


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate the Windows VC6 acceptance projects.",
    )
    parser.add_argument(
        "premake5",
        nargs="?",
        help="path to premake5 (default: $PREMAKE5, .deps, PATH)",
    )
    args = parser.parse_args()

    binary = require_premake5(args.premake5)

    work = ACC / "build"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)

    shutil.copy(ACC / "premake5.lua", work / "premake5.lua")
    shutil.copytree(ACC / "sources", work / "sources")
    shutil.copytree(ACC / "include", work / "include")

    generate(binary, work)

    workspace = work / "vc6_acceptance.dsw"
    manifest = work / "manifest.txt"
    if not workspace.is_file() or not manifest.is_file():
        print(
            "acceptance generation failed: workspace or manifest missing",
            file=sys.stderr,
        )
        return 1

    projects = len(list(work.glob("*.dsp")))
    configs = len(manifest.read_text(encoding="utf-8").splitlines())
    print(f"acceptance: generated {projects} projects / {configs} project-configs in {work}")
    print("acceptance: copy build/ to the Windows machine and run tests/acceptance/run.bat")
    return 0


if __name__ == "__main__":
    sys.exit(main())
