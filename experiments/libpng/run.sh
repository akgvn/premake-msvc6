#!/usr/bin/env bash
# experiments/libpng/run.sh - generate the libpng workspace with the vs6
# module into a shadow tree (libpng/ + sibling zlib/, mirroring the real
# cross-tree reference) and structurally diff against the real-world
# originals (real-world-test-cases/libpng) via tools/dspdiff.py.
#
# Usage: experiments/libpng/run.sh [path-to-premake5]

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
EXP=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PREMAKE5=${1:-"$REPO/../premake-sources/premake-core/bin/release/premake5"}
REAL="$REPO/real-world-test-cases/libpng"
RZLIB="$REPO/real-world-test-cases/zlib"

WORK="$EXP/build"
rm -rf "$WORK"
mkdir -p "$WORK/libpng/projects/visualc6"
cp "$EXP/premake5.lua" "$WORK/libpng/projects/visualc6/"

# premake5's file globbing only matches existing files: materialize the
# real projects' SOURCE= paths as empty placeholders in the shadow tree
# (libpng's tree, plus zlib's for the referenced zlib project)
python3 - "$REAL" "$WORK/libpng" <<'EOF'
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
python3 - "$RZLIB" "$WORK/zlib" <<'EOF'
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

(cd "$WORK/libpng/projects/visualc6" && "$PREMAKE5" --scripts="$REPO" --file=premake5.lua vs6)

set +e
python3 "$REPO/tools/dspdiff.py" \
	"$REAL/libpng.dsw"  "$WORK/libpng/projects/visualc6/libpng.dsw" \
	"$REAL/libpng.dsp"  "$WORK/libpng/projects/visualc6/libpng.dsp" \
	"$REAL/pngtest.dsp" "$WORK/libpng/projects/visualc6/pngtest.dsp"
status=$?
set -e

if [ "$status" -eq 0 ]; then
	echo "libpng experiment: all files structurally match"
else
	echo "libpng experiment: structural differences above"
fi
exit $status
