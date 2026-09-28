#!/usr/bin/env bash
# tools/test.sh - run the vs6 unit tests with the self-test harness that
# ships inside premake5 release binaries, wired to tests/_tests.lua by
# tools/run-vs6-tests.lua. Run tools/premake5.sh once to fetch the
# pinned binary, or point $PREMAKE5 at a matching premake5 install.
#
# Usage: tools/test.sh [pattern]
#   pattern   --test-only value; default "vs6*" (this module's suites);
#             "*" runs every discovered suite.

set -eu

REPO=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

. "$REPO/tools/find-premake5.sh"
PREMAKE5=$(find_premake5 "")

PATTERN=${1:-vs6*}

exec "$PREMAKE5" \
	--scripts="$REPO" \
	--file="$REPO/tools/run-vs6-tests.lua" \
	test "--test-only=$PATTERN"
