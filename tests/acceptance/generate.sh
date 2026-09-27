#!/usr/bin/env bash
# tests/acceptance/generate.sh - generate the Windows acceptance projects.
#
# Produces tests/acceptance/build/ containing vc6_acceptance.dsw, one
# .dsp per profile, the trivial sources, and manifest.txt (the list the
# Windows harness iterates). Safe to regenerate; build/ is gitignored.
#
# Usage: tests/acceptance/generate.sh [path-to-premake5]
# The premake5 binary defaults to the sibling premake-core checkout.

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
ACC=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PREMAKE5=${1:-"$REPO/../premake-sources/premake-core/bin/release/premake5"}

WORK="$ACC/build"
rm -rf "$WORK"
mkdir -p "$WORK"

cp "$ACC/premake5.lua" "$WORK/"
cp -r "$ACC/sources" "$ACC/include" "$WORK/"

(cd "$WORK" && "$PREMAKE5" --scripts="$REPO" --file=premake5.lua vs6)

if [ ! -f "$WORK/vc6_acceptance.dsw" ] || [ ! -f "$WORK/manifest.txt" ]; then
	echo "acceptance generation failed: workspace or manifest missing" >&2
	exit 1
fi

projects=$(ls "$WORK"/*.dsp | wc -l)
configs=$(wc -l < "$WORK/manifest.txt")
echo "acceptance: generated $projects projects / $configs project-configs in $WORK"
echo "acceptance: copy build/ to the Windows machine and run tests/acceptance/run.bat"
