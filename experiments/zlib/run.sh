#!/usr/bin/env bash
# experiments/zlib/run.sh - generate the zlib workspace with the vs6
# module into a shadow tree and structurally diff each file against the
# real-world originals (real-world-test-cases/zlib) via tools/dspdiff.py.
#
# Usage: experiments/zlib/run.sh [path-to-premake5]

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
EXP=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PREMAKE5=${1:-"$REPO/../premake-sources/premake-core/bin/release/premake5"}
REAL="$REPO/real-world-test-cases/zlib"

WORK="$EXP/build"
rm -rf "$WORK"
mkdir -p "$WORK/projects/visualc6"
cp "$EXP/premake5.lua" "$WORK/projects/visualc6/"

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
