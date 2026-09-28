#!/usr/bin/env bash
# experiments/zlib/run.sh - generate the zlib workspace with the vs6
# module into a shadow tree and structurally diff each file against the
# real-world originals (real-world-test-cases/zlib) via tools/dspdiff.py.
#
# Usage: experiments/zlib/run.sh [path-to-premake5]

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
EXP=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

. "$REPO/tools/find-premake5.sh"
PREMAKE5=$(find_premake5 "${1:-}")

REAL="$REPO/real-world-test-cases/zlib"

WORK="$EXP/build"
rm -rf "$WORK"
mkdir -p "$WORK/projects/visualc6"
cp "$EXP/premake5.lua" "$WORK/projects/visualc6/"

(cd "$WORK/projects/visualc6" && "$PREMAKE5" --scripts="$REPO" --file=premake5.lua vs6)

set +e
python3 "$REPO/tools/dspdiff.py" \
	"$REAL/zlib.dsw"    "$WORK/projects/visualc6/zlib.dsw" \
	"$REAL/zlib.dsp"    "$WORK/projects/visualc6/zlib.dsp" \
	"$REAL/example.dsp" "$WORK/projects/visualc6/example.dsp" \
	"$REAL/minigzip.dsp" "$WORK/projects/visualc6/minigzip.dsp"
status=$?
set -e

if [ "$status" -eq 0 ]; then
	echo "zlib experiment: all files structurally match"
else
	echo "zlib experiment: structural differences above"
fi
exit $status
