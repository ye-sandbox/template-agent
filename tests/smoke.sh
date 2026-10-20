#!/usr/bin/env bash
# ==============================================================================
# Baremetal Smoke Test Runner
# Asserts presence, executable permissions, and syntax of core ops scripts.
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REQUIRED_FILES=(
  "AGENTS.md"
  ".agent/BASELINE.md"
  ".agent/INVARIANTS.md"
  ".agent/TUNINGS.md"
  ".agent/skills/baremetal-tuning/SKILL.md"
  ".agent/TASK.md"
  ".agent/NOTES.md"
  "docs/adr/decisions.md"
  ".env.example"
  "benchmarks/README.md"
  "benchmarks/scripts/bench-cpu.sh"
  "benchmarks/scripts/bench-io.sh"
  "benchmarks/scripts/bench-latency.sh"
  "benchmarks/scripts/monitor-thermals.sh"
  "benchmarks/scripts/stream-telemetry.sh"
)

echo "🔍 Verifying baremetal contract files..."
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing required file: $file" >&2
    exit 1
  fi
done

echo "🔍 Verifying benchmark scripts are executable..."
BENCH_SCRIPTS=(
  "benchmarks/scripts/bench-cpu.sh"
  "benchmarks/scripts/bench-io.sh"
  "benchmarks/scripts/bench-latency.sh"
  "benchmarks/scripts/monitor-thermals.sh"
  "benchmarks/scripts/stream-telemetry.sh"
)

for script in "${BENCH_SCRIPTS[@]}"; do
  if [ ! -x "$script" ]; then
    echo "❌ Script is not executable: $script" >&2
    exit 1
  fi
done

echo "🔍 Checking shell script syntax with bash -n..."
for script in "${BENCH_SCRIPTS[@]}" "tests/smoke.sh"; do
  bash -n "$script" || {
    echo "❌ Syntax error in $script" >&2
    exit 1
  }
done

echo "✅ All baremetal smoke checks passed."
