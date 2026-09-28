#!/usr/bin/env bash
# tools/find-premake5.sh - locate the premake5 binary used by the repo
# scripts. Source this file with $REPO already set, then:
#
#   PREMAKE5=$(find_premake5 "${1:-}")
#
# Resolution order:
#   1. an explicit path argument (or $PREMAKE5)
#   2. the pinned binary downloaded by tools/premake5.sh
#      (.deps/premake5/premake5[.exe])
#   3. premake5 on PATH
#
# This module needs premake5 beta8 or newer (beta7 cannot load it from
# --scripts and lacks APIs the unit tests use); tools/premake5.sh
# prepares the pinned beta8 binary.

find_premake5() {
	if [ -n "${1:-}" ]; then
		echo "$1"
		return 0
	fi

	if [ -n "${PREMAKE5:-}" ]; then
		echo "$PREMAKE5"
		return 0
	fi

	local suffix=""
	case "$(uname -s)" in
		MINGW*|MSYS*|CYGWIN*) suffix=".exe" ;;
	esac

	local exe
	for exe in \
		"$REPO/.deps/premake5/premake5$suffix" \
		"$REPO/.deps/premake5/premake5" \
		"$REPO/.deps/premake5/premake5.exe"
	do
		if [ -f "$exe" ]; then
			echo "$exe"
			return 0
		fi
	done

	if command -v premake5 >/dev/null 2>&1; then
		command -v premake5
		return 0
	fi

	echo "find_premake5: no premake5 found; run tools/premake5.sh first" >&2
	return 1
}

if [ "${BASH_SOURCE[0]:-}" = "$0" ]; then
	REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
	find_premake5 "${1:-}"
fi
