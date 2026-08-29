#!/bin/sh
# Runs the CLIPSQLite test suite.
#
# Two parts, for two different reasons.
#
#   tests/test.bat        one process, every suite batched into it, one
#                         assertion counter.  This is the suite proper.
#
#   examples/*.bat        every example, run to completion and checked
#                         against the .expected file beside it.  The
#                         examples are documentation, and this is what keeps
#                         them from quietly becoming fiction.
#
# A case marked "fail" that starts passing ends this script with a non-zero
# status, the same as a case marked "pass" that fails.  A known defect that
# has been fixed is news, and the alternative is a marker nobody removes.
#
# Usage:
#   ./tests/run.sh                     the whole thing
#   ./tests/run.sh suite               only tests/test.bat
#   ./tests/run.sh examples            only the examples
#   CLIPS=/path/to/clips ./tests/run.sh
#
# With no CLIPS given this runs vendor/clips, which is a symlink to the
# CLIPS version built last.  "make test-all" runs everything below against
# all three of the versions CLIPSQLite supports, one after another.
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root" || exit 1

CLIPS=${CLIPS:-./vendor/clips/clips}
what=${1:-all}

# CLIPS may carry a prefix, as it does for the valgrind target, so the
# program being run is the last word of it that looks like a path.
clips_bin=
for word in $CLIPS; do
    case "$word" in -*) ;; *) clips_bin=$word ;; esac
done

if [ ! -x "$clips_bin" ]; then
    echo "no CLIPSQLite binary at $clips_bin -- run 'make' first," >&2
    echo "or point at one with CLIPS=/path/to/clips" >&2
    exit 1
fi

# Written by the suites, by the examples and by this script; removed at both
# ends so a run that died half way cannot seed the next one.
rm -rf tests/tmp examples/tmp
mkdir -p tests/tmp

failures=0

# ----------------------------------------------------------------------
# the in-process suite
# ----------------------------------------------------------------------

if [ "$what" = all ] || [ "$what" = suite ]; then
    $CLIPS -f2 tests/test.bat
    status=$?
    if [ "$status" -ne 0 ]; then
        failures=$((failures + 1))
        echo
        echo "FAILED: tests/test.bat (exit $status)"
    fi
fi

# ----------------------------------------------------------------------
# the examples
#
# Each one is run to completion and has to say what its .expected file says
# it says.  A line there is matched as a substring of some line of the
# output, which keeps the checks to what the example is demonstrating and
# away from what changes between machines -- a SQLite version, a page count,
# the order the agenda fired in.
#
# Writing anything to stderr fails the example too: everything in this
# library reports a refused call there, so an example that starts doing that
# has stopped working whatever it printed on the way.
# ----------------------------------------------------------------------

check_example() {
    example=$1
    expected=${example%.bat}.expected
    name=$(basename "$example")
    out=tests/tmp/${name%.bat}.out
    err=tests/tmp/${name%.bat}.err

    if [ ! -f "$expected" ]; then
        echo
        echo "FAILED: $example has no $expected beside it"
        failures=$((failures + 1))
        return
    fi

    $CLIPS -f2 "$example" >"$out" 2>"$err"
    status=$?

    if [ "$status" -ne 0 ]; then
        echo
        echo "FAILED: $example exited $status"
        sed -n '1,20p' "$err"
        failures=$((failures + 1))
        return
    fi

    if [ -s "$err" ]; then
        echo
        echo "FAILED: $example wrote to stderr"
        sed -n '1,20p' "$err"
        failures=$((failures + 1))
        return
    fi

    missing=0
    while IFS= read -r line; do
        case "$line" in ''|'#'*) continue ;; esac
        if ! grep -Fq "$line" "$out"; then
            if [ "$missing" -eq 0 ]; then
                echo
                echo "FAILED: $example did not say what $expected says it says"
            fi
            echo "  missing: $line"
            missing=$((missing + 1))
        fi
    done < "$expected"

    if [ "$missing" -gt 0 ]; then
        echo "  what it said:"
        sed 's/^/    /' "$out"
        failures=$((failures + 1))
        return
    fi

    # An example that left its scratch directory behind would seed the next
    # run of itself, and is a bug in the example rather than in what it
    # demonstrates.
    if [ -d examples/tmp ]; then
        echo
        echo "FAILED: $example left examples/tmp behind"
        rm -rf examples/tmp
        failures=$((failures + 1))
        return
    fi

    printf '.'
}

if [ "$what" = all ] || [ "$what" = examples ]; then
    # tests/test.bat removes its own scratch directory on the way out, so
    # this half puts it back rather than assuming it is still there.
    mkdir -p tests/tmp
    echo
    printf 'examples '
    for example in examples/*.bat; do
        [ -f "$example" ] || continue
        check_example "$example"
    done
    echo
fi

rm -rf tests/tmp examples/tmp

if [ "$failures" -gt 0 ]; then
    echo "FAILED"
    exit 1
fi

echo "PASSED"
