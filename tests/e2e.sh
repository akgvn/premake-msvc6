#!/usr/bin/env bash
# tests/e2e.sh - End-to-end validation of the vs6 module against the
# golden premake 3.7 oracle fixtures (PLAN.md Step 5).
#
# Runs the module on samples/premake5.lua and diffs the generated files
# against tests/golden with a normalized diff: path separators (module
# emits backslashes per OQ-7, the oracle emits forward slashes) and line
# endings (goldens are CRLF) are canonicalized; everything else must
# match byte-for-byte.
#
# Usage: tests/e2e.sh [path-to-premake5]
# The premake5 binary defaults to the sibling premake-core checkout.

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PREMAKE5=${1:-"$REPO/../premake-sources/premake-core/bin/release/premake5"}
FILES="Sample.dsw app.dsp core.dsp engine.dsp tool.dsp"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cp "$REPO/samples/premake5.lua" "$WORK/"
(cd "$WORK" && "$PREMAKE5" --scripts="$REPO" --file=premake5.lua vs6)

normalize() {
	sed 's/\\/\//g' "$1" | tr -d '\r'
}

status=0
for f in $FILES; do
	if [ ! -f "$WORK/$f" ]; then
		echo "$f: NOT GENERATED"
		status=1
	elif normalize "$WORK/$f" | cmp -s - <(normalize "$REPO/tests/golden/$f"); then
		echo "$f: OK"
	else
		echo "$f: DIFFERS"
		normalize "$WORK/$f" | diff - <(normalize "$REPO/tests/golden/$f") || true
		status=1
	fi
done

if [ "$status" -eq 0 ]; then
	echo "E2E: all files match the premake 3.7 oracle (normalized)"
else
	echo "E2E: FAILED"
fi
exit $status
