#!/usr/bin/env bash
# Cherry performance test suite: benchmarks with history tracking and comparison.
# Usage: tests/perf.sh   (override binary with CHERRY_BIN=/path/to/cherry)
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

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HISTORY_FILE="tests/perf/history/history.csv"
CURRENT_FILE="tests/perf/history/latest.csv"

# Ensure history file exists with header
if [ ! -f "$HISTORY_FILE" ]; then
  echo "timestamp,benchmark,elapsed" > "$HISTORY_FILE"
fi

echo "== performance suite =="
raw=$("$BIN" tests/perf_runner.cherry 2>&1)
summary=$(echo "$raw" | strip_ansi)

# Display the formatted output (non-RESULT lines)
echo "$raw" | grep -v '^RESULT|' | sed 's/^/    /'

# Parse RESULT lines and write to history
result_lines=$(echo "$raw" | grep '^RESULT|')
if [ -z "$result_lines" ]; then
  echo "FAIL: no RESULT lines parsed (crash?)"
  exit 1
fi

# Write current run to latest.csv
echo "timestamp,benchmark,elapsed" > "$CURRENT_FILE"
failures=0
while IFS='|' read -r _ name elapsed threshold; do
  echo "$TIMESTAMP,$name,$elapsed" >> "$CURRENT_FILE"
  echo "$TIMESTAMP,$name,$elapsed" >> "$HISTORY_FILE"
  # Check threshold
  exceeded=$(echo "$elapsed $threshold" | awk '{print ($1 > $2) ? 1 : 0}')
  if [ "$exceeded" -eq 1 ]; then
    failures=$((failures + 1))
  fi
done <<< "$result_lines"

echo ""
echo "==============================="
echo "Results written to $CURRENT_FILE"
echo "History appended to $HISTORY_FILE"

# Show comparison against last 100 runs
echo ""
echo "=== Comparison vs last 100 runs ==="
echo ""

# Get unique benchmark names from current run
bench_names=$(echo "$result_lines" | cut -d'|' -f2 | sort -u)

printf "%-35s  %10s  %10s  %10s  %10s  %s\n" "BENCHMARK" "CURRENT" "AVG(100)" "MIN" "MAX" "DELTA"
printf "%-35s  %10s  %10s  %10s  %10s  %s\n" "-----------------------------------" "----------" "----------" "----------" "----------" "------"

for bench in $bench_names; do
  # Get current value
  current=$(echo "$result_lines" | grep "|$bench|" | head -1 | cut -d'|' -f3)

  # Get last 100 values from history for this benchmark
  history_values=$(grep ",$bench," "$HISTORY_FILE" | tail -100 | cut -d',' -f3)

  if [ -n "$history_values" ]; then
    stats=$(echo "$history_values" | awk '
      BEGIN { min=999999; max=0; sum=0; n=0 }
      {
        sum += $1; n++
        if ($1 < min) min = $1
        if ($1 > max) max = $1
      }
      END {
        if (n > 0) avg = sum / n; else avg = 0
        printf "%.4f %.4f %.4f %d", avg, min, max, n
      }
    ')
    avg=$(echo "$stats" | cut -d' ' -f1)
    min_val=$(echo "$stats" | cut -d' ' -f2)
    max_val=$(echo "$stats" | cut -d' ' -f3)
    count=$(echo "$stats" | cut -d' ' -f4)

    # Calculate delta (positive = regression, negative = improvement)
    delta=$(echo "$current $avg" | awk '{
      if ($2 > 0) d = (($1 - $2) / $2) * 100; else d = 0
      printf "%+.1f%%", d
    }')

    printf "%-35s  %10s  %10s  %10s  %10s  %s\n" "$bench" "${current}s" "${avg}s" "${min_val}s" "${max_val}s" "$delta (${count} runs)"
  else
    printf "%-35s  %10s  %10s  %10s  %10s  %s\n" "$bench" "${current}s" "N/A" "N/A" "N/A" "first run"
  fi
done

echo ""
echo "==============================="
echo "total failures: $failures"
[ "$failures" -gt 0 ] && exit 1
exit 0
