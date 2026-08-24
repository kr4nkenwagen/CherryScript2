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

strip_ansi() { sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g'; }

failures=0

echo "== e2e suite =="
summary=$("$BIN" tests/testrunner.cherry 2>&1 | strip_ansi)
counts=$(echo "$summary" | grep -E '(PASSED|FAILED): [0-9]+$')
passed=$(echo "$counts" | grep 'PASSED' | tail -1 | tr -dc '0-9')
failed=$(echo "$counts" | grep 'FAILED' | tail -1 | tr -dc '0-9')
if [ -z "$passed" ] || [ -z "$failed" ]; then
  echo "FAIL could not parse suite summary (crash?)"
  echo "$summary" | tail -5 | sed 's/^/    /'
  failures=$((failures + 1))
else
  ignore_re=$(awk 'NF { printf "%s%s", sep, $0; sep="|" }' tests/expected_failures.txt 2>/dev/null)
  known=$(echo "$summary" | sed -n '/Failed tests/,$p' | grep -E 'FAILED: ' | grep -Ec "$ignore_re" || true)
  unexpected=$((failed - known))
  echo "passed: $passed  failed: $failed  (ignored: $known)"
  if [ "$unexpected" -gt 0 ]; then
    echo "unexpected failures:"
    echo "$summary" | sed -n '/Failed tests/,$p' | grep -E 'FAILED: ' | grep -Ev "$ignore_re" | sed 's/^/    /'
    failures=$((failures + unexpected))
  fi
fi

echo "== output suite =="
for f in tests/output/*.cherry; do
  name=$(basename "$f")
  actual=$("$BIN" "$f" 2>&1)
  expected=$(cat "${f%.cherry}.expected")
  if [ "$actual" = "$expected" ]; then
    echo "PASS $name"
  else
    echo "FAIL $name"
    diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | sed 's/^/    /'
    failures=$((failures + 1))
  fi
done

echo "== error suite =="
for f in tests/errors/*.cherry; do
  name=$(basename "$f")
  expected=${name%.*}
  expected=${expected##*.}
  "$BIN" "$f" >/dev/null 2>&1
  code=$?
  if [ "$code" = "$expected" ]; then
    echo "PASS $name (exit $code)"
  else
    echo "FAIL $name expected exit $expected, got $code"
    failures=$((failures + 1))
  fi
done

echo "==============================="
echo "total failures: $failures"
[ "$failures" -gt 0 ] && exit 1
exit 0
