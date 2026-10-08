#!/usr/bin/env bash
# ==============================================================================
# bench-latency.sh — Host Scheduling and Timer Latency Benchmark Runner
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$ROOT_DIR/benchmarks/runs/${TIMESTAMP}-latency"

mkdir -p "$RUN_DIR"

echo "======================================================="
echo " 🚀 Running Host Latency Benchmark"
echo " Destination: $RUN_DIR"
echo "======================================================="

TOOL="cyclictest"
MAX_LATENCY_US="0"
AVG_LATENCY_US="0"

if command -v cyclictest >/dev/null 2>&1; then
    echo "Running cyclictest (1000 loops, priority 80)..."
    cyclictest -l 1000 -m -n -p 80 -q > "$RUN_DIR/raw.log" 2>&1 || true

    # Parse output: T: 0 ( 1234) P:80 I:1000 C: 1000 Min: 2 Act: 4 Avg: 5 Max: 18
    MAX_LATENCY_US="$(grep -oE "Max:[[:space:]]*[0-9]+" "$RUN_DIR/raw.log" | awk '{print $2}' || echo "0")"
    AVG_LATENCY_US="$(grep -oE "Avg:[[:space:]]*[0-9]+" "$RUN_DIR/raw.log" | awk '{print $2}' || echo "0")"
else
    TOOL="python-highres-timer"
    echo "cyclictest not found. Falling back to high-resolution timer sleep jitter measurement..."
    
    python3 -c '
import time, json, sys

samples = []
target_sleep = 0.001 # 1ms

for _ in range(500):
    start = time.perf_counter()
    time.sleep(target_sleep)
    elapsed = time.perf_counter() - start
    jitter_us = max(0, (elapsed - target_sleep) * 1_000_000)
    samples.append(jitter_us)

samples.sort()
avg_jitter = sum(samples) / len(samples)
max_jitter = max(samples)
p99_jitter = samples[int(len(samples) * 0.99)]

result = {
    "tool": "python-highres-timer",
    "samples_count": len(samples),
    "avg_latency_us": round(avg_jitter, 2),
    "p99_latency_us": round(p99_jitter, 2),
    "max_latency_us": round(max_jitter, 2)
}
with open("'"$RUN_DIR"'/raw.json", "w") as f:
    json.dump(result, f, indent=2)

print(f"Avg: {round(avg_jitter, 2)}us, P99: {round(p99_jitter, 2)}us, Max: {round(max_jitter, 2)}us")
' > "$RUN_DIR/raw.log" 2>&1 || true

    if [ -f "$RUN_DIR/raw.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            MAX_LATENCY_US="$(jq -r '.max_latency_us' "$RUN_DIR/raw.json" 2>/dev/null || echo "0")"
            AVG_LATENCY_US="$(jq -r '.avg_latency_us' "$RUN_DIR/raw.json" 2>/dev/null || echo "0")"
        else
            MAX_LATENCY_US="$(grep -oE '"max_latency_us":[[:space:]]*[0-9.]+' "$RUN_DIR/raw.json" | awk -F: '{print $2}' | tr -d ' ' || echo "0")"
            AVG_LATENCY_US="$(grep -oE '"avg_latency_us":[[:space:]]*[0-9.]+' "$RUN_DIR/raw.json" | awk -F: '{print $2}' | tr -d ' ' || echo "0")"
        fi
    fi
fi

cat <<EOF > "$RUN_DIR/summary.json"
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$(hostname)",
  "tool": "$TOOL",
  "avg_latency_us": "$AVG_LATENCY_US",
  "max_latency_us": "$MAX_LATENCY_US"
}
EOF

echo ""
echo "✅ Latency Benchmark Completed."
cat "$RUN_DIR/summary.json"
echo ""
echo "💡 Summarize these findings into .agent/BASELINE.md or .agent/TUNINGS.md"
