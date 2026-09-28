#!/usr/bin/env bash
# experiments/peter/run.sh - generate the Peter workspace with the vs6
# module into a shadow tree and structurally diff each file against the
# real-world originals (real-world-test-cases/peter) via tools/dspdiff.py.
#
# Usage: experiments/peter/run.sh [path-to-premake5]

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
EXP=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

. "$REPO/tools/find-premake5.sh"
PREMAKE5=$(find_premake5 "${1:-}")

REAL="$REPO/real-world-test-cases/peter"

WORK="$EXP/build"
rm -rf "$WORK"
mkdir -p "$WORK"
cp "$EXP/premake5.lua" "$WORK/"

# premake5's file globbing only matches existing files: materialize the
# real projects' SOURCE= paths as empty placeholders in the shadow tree
python3 - "$REAL" "$WORK" <<'EOF'
import os, re, sys
real, work = sys.argv[1], sys.argv[2]
for root, _, names in os.walk(real):
    for name in names:
        if not name.lower().endswith(".dsp"):
            continue
        prjdir = os.path.relpath(root, real)
        with open(os.path.join(root, name), newline="") as f:
            text = f.read()
        for m in re.finditer(r'^SOURCE="?([^"\r\n]+)"?', text, re.M):
            src = m.group(1).replace("\\", "/")
            if src.startswith("./"):
                src = src[2:]
            dst = os.path.normpath(os.path.join(work, prjdir, src))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            open(dst, "a").close()
EOF

(cd "$WORK" && "$PREMAKE5" --scripts="$REPO" --file=premake5.lua vs6)

set +e
python3 "$REPO/tools/dspdiff.py" \
	"$REAL/Peter.dsw"            "$WORK/Peter.dsw" \
	"$REAL/Peter.dsp"            "$WORK/Peter.dsp" \
	"$REAL/DataInst/DataInst.dsp" "$WORK/DataInst/DataInst.dsp" \
	"$REAL/DelExe/DelExe.dsp"    "$WORK/DelExe/DelExe.dsp" \
	"$REAL/Gener/Gener.dsp"      "$WORK/Gener/Gener.dsp" \
	"$REAL/Loader/Peter.dsp"     "$WORK/Loader/Peter.dsp" \
	"$REAL/Loader0/Peter.dsp"    "$WORK/Loader0/Peter.dsp" \
	"$REAL/Pov2Spr/Pov2Spr.dsp"  "$WORK/Pov2Spr/Pov2Spr.dsp" \
	"$REAL/Setup/Setup.dsp"      "$WORK/Setup/Setup.dsp"
status=$?
set -e

if [ "$status" -eq 0 ]; then
	echo "peter experiment: all files structurally match"
else
	echo "peter experiment: structural differences above"
fi
exit $status
