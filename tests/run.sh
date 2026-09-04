#!/usr/bin/env bash
# Cherry test suite runner: e2e assertions + output snapshots + error exit codes.
# Also runs full performance benchmarks (history + threshold assertions).
# Usage: tests/run.sh   (override binary with CHERRY_BIN=/path/to/cherry)
set -u
cd "$(dirname "$0")/.."

BIN="${CHERRY_BIN:-}"
if [ -z "$BIN" ]; then
  BIN="$(mktemp -d)/cherry"
  echo "== Building interpreter..."
  odin build src -o:speed -out:"$BIN" || { echo "build failed"; exit 1; }
fi

mkdir -p tests/tmp tests/perf/history
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

echo "== unit tests =="
unit_fail=0
unit_total=0
unit_ran=0
for tf in src/*/*_test.odin; do
  [ -e "$tf" ] || continue
  pkg=$(basename "$(dirname "$tf")")
  tmp="tests/tmp/unit_${pkg}"
  out=$(odin test "src/$pkg" -out:"$tmp" 2>&1)
  rm -f "$tmp" 2>/dev/null
  if echo "$out" | grep -q "All tests were successful"; then
    echo "PASS  $pkg"
  else
    echo "FAIL  $pkg"
    echo "$out" | strip_ansi | grep -aE 'Error:|failed|Assertion' | sed 's/^/      /' | head -20
    unit_fail=$((unit_fail + 1))
  fi
  unit_ran=$((unit_ran + 1))
  n=$(echo "$out" | grep -aoE 'Finished [0-9]+ tests' | grep -aoE '[0-9]+' | head -1)
  if [ -n "$n" ]; then
    unit_total=$((unit_total + n))
  fi
done
echo "unit tests: packages=$unit_ran  tests=$unit_total  failures=$unit_fail"
if [ "$unit_fail" -gt 0 ]; then
  failures=$((failures + unit_fail))
fi
echo "==============================="

echo "== performance benchmarks =="
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HISTORY_FILE="tests/perf/history/history.csv"
RAW_PERF=$("$BIN" tests/perf_runner.cherry 2>&1)

# Show formatted output (non-RESULT lines)
echo "$RAW_PERF" | grep -v '^RESULT|' | strip_ansi

result_lines=$(echo "$RAW_PERF" | grep '^RESULT|')
if [ -z "$result_lines" ]; then
  echo "FAIL could not parse benchmark results (crash?)"
  failures=$((failures + 1))
else
  if [ ! -f "$HISTORY_FILE" ]; then
    echo "timestamp,benchmark,elapsed" > "$HISTORY_FILE"
  fi
  echo "timestamp,benchmark,elapsed" > tests/perf/history/latest.csv
  while IFS='|' read -r _ name elapsed threshold; do
    echo "$TIMESTAMP,$name,$elapsed" >> "$HISTORY_FILE"
    echo "$TIMESTAMP,$name,$elapsed" >> tests/perf/history/latest.csv
    exceeded=$(echo "$elapsed $threshold" | awk '{print ($1 > $2) ? 1 : 0}')
    if [ "$exceeded" -eq 1 ]; then
      echo "FAILED benchmark: $name (${elapsed}s > ${threshold}s)"
      failures=$((failures + 1))
    fi
  done <<< "$result_lines"
  echo "benchmarks written to: $HISTORY_FILE"
fi
echo "==============================="
echo "total failures: $failures"
[ "$failures" -gt 0 ] && exit 1
exit 0
