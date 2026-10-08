#!/usr/bin/env bash
# ==============================================================================
# monitor-thermals.sh — Hardware Sensors, Clocks, and Thermals Snapshot
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$ROOT_DIR/benchmarks/runs/${TIMESTAMP}-thermals"

mkdir -p "$RUN_DIR"

echo "======================================================="
echo " 🌡️ Capturing Hardware Thermals and Clocks"
echo " Destination: $RUN_DIR"
echo " Host:        $(hostname)"
echo "======================================================="

MAX_CPU_TEMP_C="unknown"
AVG_CPU_FREQ_MHZ="unknown"

# 1. Capture sysfs thermal zones
if compgen -G "/sys/class/thermal/thermal_zone*" > /dev/null; then
    echo "=== /sys/class/thermal/ ===" >> "$RUN_DIR/raw.log"
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -f "$zone/temp" ] && [ -f "$zone/type" ]; then
            TYPE="$(cat "$zone/type")"
            RAW_TEMP="$(cat "$zone/temp" 2>/dev/null || echo "0")"
            TEMP_C="$(awk -v t="$RAW_TEMP" 'BEGIN { printf "%.1f", t / 1000 }')"
            echo "Zone $(basename "$zone") ($TYPE): ${TEMP_C}°C" >> "$RUN_DIR/raw.log"
        fi
    done
fi

# 2. Capture lm-sensors if available
if command -v sensors >/dev/null 2>&1; then
    echo -e "\n=== lm-sensors ===" >> "$RUN_DIR/raw.log"
    sensors >> "$RUN_DIR/raw.log" 2>&1 || true
    
    # Try parsing highest temperature
    PARSED_MAX="$(sensors 2>/dev/null | grep -oE '\+[0-9]+\.[0-9]+°C' | tr -d '+°C' | sort -nr | head -n 1 || true)"
    if [ -n "$PARSED_MAX" ]; then
        MAX_CPU_TEMP_C="$PARSED_MAX"
    fi
fi

# 3. Capture CPU frequencies
if compgen -G "/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq" > /dev/null; then
    echo -e "\n=== CPU Scaling Frequencies ===" >> "$RUN_DIR/raw.log"
    TOTAL_FREQ=0
    COUNT=0
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
        FREQ_KHZ="$(cat "$f" 2>/dev/null || echo "0")"
        TOTAL_FREQ=$((TOTAL_FREQ + FREQ_KHZ))
        COUNT=$((COUNT + 1))
    done
    if [ "$COUNT" -gt 0 ]; then
        AVG_CPU_FREQ_MHZ="$(( (TOTAL_FREQ / COUNT) / 1000 ))"
        echo "Average CPU frequency across $COUNT cores: ${AVG_CPU_FREQ_MHZ} MHz" >> "$RUN_DIR/raw.log"
    fi
fi

# 4. Capture GPU if nvidia-smi is available
if command -v nvidia-smi >/dev/null 2>&1; then
    echo -e "\n=== NVIDIA GPU ===" >> "$RUN_DIR/raw.log"
    nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,power.draw --format=csv >> "$RUN_DIR/raw.log" 2>&1 || true
fi

cat <<EOF > "$RUN_DIR/summary.json"
{
  "timestamp": "$TIMESTAMP",
  "hostname": "$(hostname)",
  "max_cpu_temp_c": "$MAX_CPU_TEMP_C",
  "avg_cpu_freq_mhz": "$AVG_CPU_FREQ_MHZ"
}
EOF

echo ""
echo "✅ Thermal Snapshot Completed."
cat "$RUN_DIR/summary.json"
echo ""
echo "💡 Summarize these findings into .agent/BASELINE.md or .agent/TUNINGS.md"
