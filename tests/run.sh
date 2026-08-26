#!/bin/sh
# Runs the CLIPSQLite test suite.
#
# Two parts, for two different reasons.
#
#   tests/test.bat        one process, every suite batched into it, one
#                         assertion counter.  This is the suite proper.
#
# A case marked "fail" that starts passing ends this script with a non-zero
# status, the same as a case marked "pass" that fails.  A known defect that
# has been fixed is news, and the alternative is a marker nobody removes.
#
# Usage:
#   ./tests/run.sh                     the whole thing
#   ./tests/run.sh suite               only tests/test.bat
#   CLIPS=/path/to/clips ./tests/run.sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root" || exit 1

CLIPS=${CLIPS:-./vendor/clips/clips}
what=${1:-all}

if [ ! -x "$CLIPS" ]; then
    echo "no CLIPSQLite binary at $CLIPS -- run 'make' first," >&2
    echo "or point at one with CLIPS=/path/to/clips" >&2
    exit 1
fi

# Written by the suites and by this script; removed at both ends so a run that
# died half way cannot seed the next one.
rm -rf tests/tmp
mkdir -p tests/tmp

failures=0
xfail=0

# ----------------------------------------------------------------------
# the in-process suite
# ----------------------------------------------------------------------

if [ "$what" = all ] || [ "$what" = suite ]; then
    "$CLIPS" -f2 tests/test.bat
    status=$?
    if [ "$status" -ne 0 ]; then
        failures=$((failures + 1))
        echo
        echo "FAILED: tests/test.bat (exit $status)"
    fi
fi

rm -rf tests/tmp

if [ "$failures" -gt 0 ]; then
    echo "FAILED"
    exit 1
fi

echo "PASSED"
