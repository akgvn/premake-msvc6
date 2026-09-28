#!/usr/bin/env bash
# experiments/quake2/run.sh - generate the Quake 2 workspace with the vs6
# module into a shadow tree and structurally diff each file against the
# real-world originals (real-world-test-cases/quake2) via tools/dspdiff.py.
#
# Usage: experiments/quake2/run.sh [path-to-premake5]

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
EXP=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

. "$REPO/tools/find-premake5.sh"
PREMAKE5=$(find_premake5 "${1:-}")

REAL="$REPO/real-world-test-cases/quake2"

WORK="$EXP/build/quake2"
rm -rf "$WORK"
mkdir -p "$WORK"
cp "$EXP/premake5.lua" "$WORK/"

(cd "$WORK" && "$PREMAKE5" --scripts="$REPO" --file=premake5.lua vs6)

set +e
python3 "$REPO/tools/dspdiff.py" \
	"$REAL/quake2.dsw"        "$WORK/quake2.dsw" \
	"$REAL/quake2.dsp"        "$WORK/quake2.dsp" \
	"$REAL/ctf/ctf.dsp"       "$WORK/ctf/ctf.dsp" \
	"$REAL/game/game.dsp"     "$WORK/game/game.dsp" \
	"$REAL/ref_gl/ref_gl.dsp" "$WORK/ref_gl/ref_gl.dsp" \
	"$REAL/ref_soft/ref_soft.dsp" "$WORK/ref_soft/ref_soft.dsp"
status=$?
set -e

if [ "$status" -eq 0 ]; then
	echo "quake2 experiment: all files structurally match"
else
	echo "quake2 experiment: structural differences above"
fi
exit $status
