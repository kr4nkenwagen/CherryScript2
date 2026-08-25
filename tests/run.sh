#!/usr/bin/env bash
# Cherry test suite runner: e2e assertions + output snapshots + error exit codes.
# Usage: tests/run.sh   (override binary with CHERRY_BIN=/path/to/cherry)
set -u
cd "$(dirname "$0")/.."

BIN="${CHERRY_BIN:-}"
if [ -z "$BIN" ]; then
  BIN="$(mktemp -d)/cherry"
  echo "== Building interpreter..."
  odin build src -o:speed -out:"$BIN" || { echo "build failed"; exit 1; }
fi

mkdir -p tests/tmp
ln -sfn "$BIN" tests/tmp/cherry

strip_ansi() { sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g'; }

failures=0

echo "== test suite =="
summary=$("$BIN" tests/testrunner.cherry 2>&1 | strip_ansi)
counts=$(echo "$summary" | grep -E '(PASSED|FAILED): [0-9]+$')
passed=$(echo "$counts" | grep 'PASSED' | tail -1 | tr -dc '0-9')
failed=$(echo "$counts" | grep 'FAILED' | tail -1 | tr -dc '0-9')
if [ -z "$passed" ] || [ -z "$failed" ]; then
  echo "FAIL could not parse suite summary (crash?)"
  echo "$summary" | tail -5 | sed 's/^/    /'
  failures=$((failures + 1))
else
  ignore_re=""
  if [ -s tests/expected_failures.txt ]; then
    ignore_re=$(awk 'NF { printf "%s%s", sep, $0; sep="|" }' tests/expected_failures.txt)
  fi
  if [ -n "$ignore_re" ]; then
    known=$(echo "$summary" | sed -n '/Failed tests/,$p' | grep -E 'FAILED: ' | grep -Ec "$ignore_re" || true)
  else
    known=0
  fi
  unexpected=$((failed - known))
  echo "passed: $passed  failed: $failed  (ignored: $known)"
  if [ "$unexpected" -gt 0 ]; then
    echo "unexpected failures:"
    if [ -n "$ignore_re" ]; then
      echo "$summary" | sed -n '/Failed tests/,$p' | grep -E 'FAILED: ' | grep -Ev "$ignore_re" | sed 's/^/    /'
    else
      echo "$summary" | sed -n '/Failed tests/,$p' | grep -E 'FAILED: ' | sed 's/^/    /'
    fi
    failures=$((failures + unexpected))
  fi
fi
echo "==============================="
echo "total failures: $failures"
[ "$failures" -gt 0 ] && exit 1
exit 0
