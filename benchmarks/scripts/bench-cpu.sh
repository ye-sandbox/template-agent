#!/usr/bin/env bash
# ==============================================================================
# bench-cpu.sh — Host CPU Performance Benchmark Runner
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$ROOT_DIR/benchmarks/runs/${TIMESTAMP}-cpu"

mkdir -p "$RUN_DIR"

echo "======================================================="
echo " 🚀 Running CPU Benchmark"
echo " Destination: $RUN_DIR"
echo " Host:        $(hostname) ($(uname -m))"
echo " Cores:       $(nproc)"
echo "======================================================="

TOOL="sysbench"
EVENTS_PER_SEC="0"
EXEC_TIME_SEC="0"

if command -v sysbench >/dev/null 2>&1; then
    echo "Running sysbench (threads=$(nproc), prime limit=20000)..."
    sysbench cpu --threads="$(nproc)" --cpu-max-prime=20000 run > "$RUN_DIR/raw.log" 2>&1 || true

    EVENTS_PER_SEC="$(grep -E "events per second:" "$RUN_DIR/raw.log" | awk '{print $4}' || echo "0")"
    EXEC_TIME_SEC="$(grep -E "total time:" "$RUN_DIR/raw.log" | awk '{print $3}' | tr -d 's' || echo "0")"
else
    TOOL="builtin-multithread-compute"
    echo "sysbench not installed. Falling back to multi-core sha256 checksum compute test..."

    START_NS="$(date +%s%N)"
    PIDS=()
    for ((i=0; i<$(nproc); i++)); do
        ( head -c 50M /dev/zero | sha256sum > /dev/null ) &
        PIDS+=($!)
    done
    for pid in "${PIDS[@]}"; do
        wait "$pid"
    done
    END_NS="$(date +%s%N)"

    DURATION_MS="$(( (END_NS - START_NS) / 1000000 ))"
    EXEC_TIME_SEC="$(awk -v ms="$DURATION_MS" 'BEGIN { printf "%.3f", ms / 1000 }')"
    echo "Completed 50MB per-core sha256 computation in ${EXEC_TIME_SEC}s" > "$RUN_DIR/raw.log"
fi

cat <<EOF > "$RUN_DIR/summary.json"
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$(hostname)",
  "tool": "$TOOL",
  "cores": $(nproc),
  "events_per_sec": "$EVENTS_PER_SEC",
  "execution_time_seconds": "$EXEC_TIME_SEC"
}
EOF

echo ""
echo "✅ Benchmark Completed."
cat "$RUN_DIR/summary.json"
echo ""
echo "💡 Summarize these findings into .agent/BASELINE.md or .agent/TUNINGS.md"
