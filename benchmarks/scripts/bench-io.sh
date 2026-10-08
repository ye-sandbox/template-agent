#!/usr/bin/env bash
# ==============================================================================
# bench-io.sh — Storage Throughput and I/O Benchmark Runner
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$ROOT_DIR/benchmarks/runs/${TIMESTAMP}-io"
TEST_FILE="/tmp/baremetal-io-bench-${TIMESTAMP}.dat"

mkdir -p "$RUN_DIR"

cleanup() {
    rm -f "$TEST_FILE"
}
trap cleanup EXIT

echo "======================================================="
echo " 🚀 Running Storage I/O Benchmark"
echo " Destination: $RUN_DIR"
echo " Test Target: $TEST_FILE"
echo "======================================================="

TOOL="fio"
THROUGHPUT_MB_S="0"
IOPS="0"
LATENCY_MS="0"

if command -v fio >/dev/null 2>&1; then
    echo "Running fio (100MB randwrite direct I/O)..."
    fio --name=iobench \
        --filename="$TEST_FILE" \
        --size=100M \
        --rw=randwrite \
        --bs=4k \
        --direct=1 \
        --numjobs=1 \
        --time_based=0 \
        --output-format=json \
        --output="$RUN_DIR/raw.json" || true

    # Extract throughput and iops if jq is available
    if command -v jq >/dev/null 2>&1 && [ -f "$RUN_DIR/raw.json" ]; then
        THROUGHPUT_MB_S="$(jq -r '.jobs[0].write.bw_bytes / 1048576' "$RUN_DIR/raw.json" 2>/dev/null || echo "0")"
        IOPS="$(jq -r '.jobs[0].write.iops' "$RUN_DIR/raw.json" 2>/dev/null || echo "0")"
        LATENCY_MS="$(jq -r '.jobs[0].write.lat_ns.mean / 1000000' "$RUN_DIR/raw.json" 2>/dev/null || echo "0")"
    fi
else
    TOOL="dd-direct-sync"
    echo "fio not found. Falling back to non-destructive synchronized dd test (100MB)..."
    
    DD_OUTPUT="$(dd if=/dev/zero of="$TEST_FILE" bs=1M count=100 oflag=dsync conv=fdatasync 2>&1)"
    echo "$DD_OUTPUT" > "$RUN_DIR/raw.log"
    
    # Extract speed from dd output (e.g., "104 MB/s" or "1.2 GB/s")
    SPEED_STR="$(echo "$DD_OUTPUT" | grep -oE '[0-9.]+ [kKMGT]?B/s' | tail -n 1 || echo "0 MB/s")"
    THROUGHPUT_MB_S="$SPEED_STR"
fi

cat <<EOF > "$RUN_DIR/summary.json"
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$(hostname)",
  "tool": "$TOOL",
  "throughput_mb_s": "$THROUGHPUT_MB_S",
  "iops": "$IOPS",
  "mean_latency_ms": "$LATENCY_MS"
}
EOF

echo ""
echo "✅ I/O Benchmark Completed."
cat "$RUN_DIR/summary.json"
echo ""
echo "💡 Summarize these findings into .agent/BASELINE.md or .agent/TUNINGS.md"
