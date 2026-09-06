#!/usr/bin/env bash
# Assert scaffolding + guardrail contracts on a generated starter.
# Usage: assert-starter-contracts.sh <greenfield|brownfield|blackbox|infra> <dir>
set -euo pipefail

KIND="${1:-}"
ROOT="${2:-}"

if [ -z "$KIND" ] || [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
  echo "Usage: $0 <greenfield|brownfield|blackbox|infra> <generated-dir>" >&2
  exit 2
fi

fail() {
  echo "❌ [$KIND] $*" >&2
  exit 1
}

need_file() {
  [ -f "$ROOT/$1" ] || fail "missing file: $1"
}

need_dir() {
  [ -d "$ROOT/$1" ] || fail "missing directory: $1"
}

need_absent() {
  [ ! -e "$ROOT/$1" ] || fail "must not exist: $1"
}

need_grep() {
  local file="$1" pattern="$2" flags="${3:--qE}"
  grep $flags "$pattern" "$ROOT/$file" >/dev/null || fail "expected /$pattern/ in $file"
}

need_one_commit() {
  local count
  count="$(git -C "$ROOT" rev-list --count HEAD)"
  [ "$count" -eq 1 ] || fail "expected exactly 1 git commit, got $count"
}

assert_greenfield() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/skills/database-migration/SKILL.md
  need_file .agent/skills/api-endpoint/SKILL.md
  need_file .agent/adr/000-template.md
  need_dir .git
  need_absent init.sh
  need_one_commit
  need_grep AGENTS.md '.agent/TASK.md' -qF
  need_grep AGENTS.md '.agent/NOTES.md' -qF
  need_grep AGENTS.md 'circuit breaker' -qiE
  need_grep .gitignore '.env' -qF
  need_grep .gitignore '!.env.example' -qF
  if grep -q 'Checklist de adaptação' "$ROOT/AGENTS.md"; then
    fail "adaptation checklist leaked into generated AGENTS.md"
  fi
}

assert_brownfield() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/INVARIANTS.md
  need_file .agent/TASK.md
  need_file .agent/NOTES.md
  need_file .agent/ARCHIVE.md
  need_grep AGENTS.md '.agent/INVARIANTS.md' -qF
  need_grep AGENTS.md 'caracteriza' -qiE
  need_grep AGENTS.md 'git push' -qiF
  need_grep .agent/INVARIANTS.md 'Chesterton' -qF
}

assert_blackbox() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/ENDPOINTS.md
  need_file .agent/skills/reverse-engineering/SKILL.md
  need_file .agent/TASK.md
  need_file .agent/NOTES.md
  need_file .agent/ARCHIVE.md
  need_file .env.example
  need_file .gitignore
  need_dir .git
  need_absent init.sh
  need_one_commit
  need_grep AGENTS.md 'git push' -qiF
  need_grep AGENTS.md 'fixture' -qiE
  need_grep .gitignore '.env' -qF
  need_grep .gitignore '*.har' -qF
  need_grep .gitignore 'tests/fixtures/real/' -qF
  need_grep .agent/ENDPOINTS.md '$TARGET_SESSION_COOKIE' -qF
  if grep -RIE --exclude-dir=.git 'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.' "$ROOT"; then
    fail "JWT-like token found in scaffold"
  fi
}

assert_infra() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/SERVICES.md
  need_file .agent/skills/compose-service/SKILL.md
  need_file .agent/TASK.md
  need_file .agent/NOTES.md
  need_file .agent/ARCHIVE.md
  need_file .env.example
  need_file .gitignore
  need_file compose.yaml.example
  need_dir .git
  need_absent init.sh
  need_one_commit
  need_grep AGENTS.md 'down -v' -qF
  need_grep AGENTS.md ':latest' -qF
  need_grep AGENTS.md 'healthcheck' -qF
  local healthcheck_count
  healthcheck_count="$(grep -c '^    healthcheck:' "$ROOT/compose.yaml.example" || true)"
  [ "$healthcheck_count" -ge 2 ] || fail "expected at least 2 healthchecks in compose.yaml.example, got $healthcheck_count"
  if grep -qE 'image:[[:space:]]*[^[:space:]]+:latest' "$ROOT/compose.yaml.example"; then
    fail ":latest image tag found in compose.yaml.example"
  fi
  docker compose --env-file "$ROOT/.env.example" -f "$ROOT/compose.yaml.example" config --quiet
}

case "$KIND" in
  greenfield) assert_greenfield ;;
  brownfield) assert_brownfield ;;
  blackbox) assert_blackbox ;;
  infra) assert_infra ;;
  *)
    echo "Unknown starter kind: $KIND" >&2
    exit 2
    ;;
esac

echo "✅ $KIND starter contracts passed ($ROOT)"
