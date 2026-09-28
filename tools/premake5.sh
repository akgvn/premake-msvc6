#!/usr/bin/env bash
# tools/premake5.sh - prepare the pinned premake5 binary used to build
# and test this module, without a premake-core checkout:
#
#   1. use an installed premake5 if its version matches the pinned tag
#   2. otherwise download the official release archive into
#      .deps/premake5/ (gitignored)
#   3. run the vs6 unit tests via tools/test.sh
#
# The self-test harness ships inside premake5 release binaries;
# tools/run-vs6-tests.lua wires it to tests/_tests.lua. No compiler,
# Bootstrap, or premake-core clone is needed.
#
# Usage: tools/premake5.sh [options]
#   --tag TAG    premake5 release tag (default: v5.0.0-beta8)
#   --no-test    skip the unit test run
#   --clean      remove .deps/
#   -h, --help   show this help
#
# Environment:
#   PREMAKE5     binary to prefer, if its version matches the tag

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
DEPS="$REPO/.deps"
BINDIR="$DEPS/premake5"
TAG="v5.0.0-beta8"
RUN_TESTS=1
CLEAN=0

usage() {
	sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
	case "$1" in
		--tag)
			[ $# -ge 2 ] || { echo "premake5.sh: --tag needs a value" >&2; exit 2; }
			TAG=$2
			shift 2
			;;
		--no-test) RUN_TESTS=0; shift ;;
		--clean) CLEAN=1; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "premake5.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
done

VERSION=${TAG#v}

# Which release asset to fetch.
case "$(uname -s)" in
	MINGW*|MSYS*|CYGWIN*)
		HOST=windows
		ASSET="premake-$VERSION-windows.zip"
		EXE="premake5.exe"
		;;
	Darwin*)
		HOST=macosx
		ASSET="premake-$VERSION-macosx.tar.gz"
		EXE="premake5"
		;;
	*)
		HOST=linux
		ASSET="premake-$VERSION-linux.tar.gz"
		EXE="premake5"
		;;
esac

version_of() {
	"$1" --version 2>/dev/null | sed -n 's/.*Generator) //p'
}

# Windows path for the Expand-Archive fallback.
wpath() {
	case "$HOST" in
		windows) cygpath -w "$1" ;;
		*) echo "$1" ;;
	esac
}

extract_archive() {
	local archive=$1 dest=$2
	case "$archive" in
		*.zip)
			if command -v unzip >/dev/null 2>&1; then
				unzip -oq "$archive" -d "$dest"
			elif command -v powershell.exe >/dev/null 2>&1; then
				powershell.exe -NoProfile -Command \
					"Expand-Archive -LiteralPath '$(wpath "$archive")' -DestinationPath '$(wpath "$dest")' -Force"
			else
				echo "premake5.sh: cannot extract $archive (need unzip)" >&2
				return 1
			fi
			;;
		*)
			tar -xzf "$archive" -C "$dest"
			;;
	esac
}

find_binary() {
	if [ -x "$BINDIR/$EXE" ] && [ "$(version_of "$BINDIR/$EXE")" = "$VERSION" ]; then
		BIN="$BINDIR/$EXE"
		echo "premake5.sh: using downloaded premake5 $VERSION ($BIN)"
		return 0
	fi
	# Drop a download from a previous --tag so tools/test.sh cannot
	# resolve to the stale binary.
	if [ -e "$BINDIR/$EXE" ] && [ "$(version_of "$BINDIR/$EXE")" != "$VERSION" ]; then
		rm -f "$BINDIR/$EXE"
	fi
	local cand
	for cand in "${PREMAKE5:-}" "$(command -v premake5 2>/dev/null || true)"; do
		if [ -n "$cand" ] && [ "$(version_of "$cand")" = "$VERSION" ]; then
			BIN=$cand
			echo "premake5.sh: using installed premake5 $VERSION ($cand)"
			return 0
		fi
	done
	return 1
}

download_binary() {
	local url="https://github.com/premake/premake-core/releases/download/$TAG/$ASSET" got
	mkdir -p "$BINDIR"
	echo "premake5.sh: downloading $url"
	if command -v curl >/dev/null 2>&1; then
		curl -fL --retry 2 -o "$BINDIR/$ASSET" "$url"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$BINDIR/$ASSET" "$url"
	else
		echo "premake5.sh: need curl or wget to download premake5" >&2
		return 1
	fi
	extract_archive "$BINDIR/$ASSET" "$BINDIR"
	BIN="$BINDIR/$EXE"
	[ "$HOST" = windows ] || chmod +x "$BIN"
	got=$(version_of "$BIN")
	if [ "$got" != "$VERSION" ]; then
		echo "premake5.sh: unexpected binary version '$got' (want $VERSION)" >&2
		return 1
	fi
	echo "premake5.sh: using downloaded premake5 $VERSION ($BIN)"
}

if [ "$CLEAN" = 1 ]; then
	rm -rf "$DEPS"
	echo "premake5.sh: removed $DEPS"
	exit 0
fi

BIN=""
if ! find_binary; then
	download_binary
fi

if [ "$RUN_TESTS" = 1 ]; then
	echo "premake5.sh: running vs6 unit tests"
	exec "$REPO/tools/test.sh"
fi

echo "premake5.sh: ready ($BIN)"
