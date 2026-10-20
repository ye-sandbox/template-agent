#!/usr/bin/env bash
# ==============================================================================
# Blackbox Smoke Test Runner
# Asserts presence of core reverse engineering contracts and files.
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REQUIRED_FILES=(
  "AGENTS.md"
  ".agent/ENDPOINTS.md"
  ".agent/TASK.md"
  ".agent/NOTES.md"
  ".agent/ARCHIVE.md"
  ".agent/knowledge/000-schema.md"
  ".agent/knowledge/k-000-template.md"
  ".agent/knowledge/k-001-soft-200-session-expiry-detection.md"
  ".agent/skills/reverse-engineering/SKILL.md"
  "docs/adr/decisions.md"
  ".env.example"
  ".gitignore"
)

echo "🔍 Verifying blackbox contract files..."
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Missing required file: $file" >&2
    exit 1
  fi
done

echo "🔍 Checking shell script syntax with bash -n..."
for script in "tests/smoke.sh"; do
  bash -n "$script" || {
    echo "❌ Syntax error in $script" >&2
    exit 1
  }
done

echo "✅ All blackbox smoke checks passed."
