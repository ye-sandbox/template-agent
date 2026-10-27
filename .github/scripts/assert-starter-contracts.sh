#!/usr/bin/env bash
# Assert scaffolding + guardrail contracts on a generated starter.
# Usage: assert-starter-contracts.sh <greenfield|greenfield-standalone|brownfield|brownfield-stealth|blackbox|infra|baremetal> <dir>
set -euo pipefail

KIND="${1:-}"
ROOT="${2:-}"

if [ -z "$KIND" ] || [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
  echo "Usage: $0 <greenfield|greenfield-standalone|brownfield|brownfield-stealth|blackbox|infra|baremetal> <generated-dir>" >&2
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

need_clean_smoke_test() {
  if [ -f "$ROOT/package.json" ]; then
    ( cd "$ROOT" && npm test ) || fail "smoke test failed via npm test in $ROOT"
  fi
}

assert_product_readme() {
  need_file README.md
  need_file README.pt-br.md
  need_grep README.md '^## Overview$' -qE
  need_grep README.md '^## Architecture$' -qE
  need_grep README.md '^## Quickstart$' -qE
  need_grep README.md '^## Configuration$' -qE
  need_grep README.md '^## Development$' -qE
  need_grep README.md '^## License$' -qE
  need_grep README.pt-br.md '^## Visão Geral$' -qE
  need_grep README.pt-br.md '^## Arquitetura$' -qE
  need_grep README.pt-br.md '^## Início Rápido$' -qE
  need_grep README.pt-br.md '^## Configuração$' -qE
  need_grep README.pt-br.md '^## Desenvolvimento$' -qE
  need_grep README.pt-br.md '^## Licença$' -qE
  if grep -qE 'Agent-Driven Development \(ADD\) Template|Option 1: Automated One-Liner' "$ROOT/README.md" "$ROOT/README.pt-br.md"; then
    fail "template instructional README leaked into generated product repository"
  fi
}

assert_greenfield_base() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/skills/000-template.md
  need_file .agent/skills/README.md
  need_absent .agent/skills/database-migration
  need_absent .agent/skills/api-endpoint
  need_file .agent/knowledge/000-schema.md
  need_file .agent/knowledge/k-000-template.md
  need_file docs/adr/decisions.md
  need_file .agent/TASK.md
  need_grep .agent/TASK.md 'Task \[00\.1\]: Project Bootstrap & Stack Setup' -qE
  if grep -qF 'Task [XX.Y]' "$ROOT/.agent/TASK.md"; then
    fail "unresolved Task [XX.Y] placeholder found in .agent/TASK.md"
  fi
  need_dir .git
  need_absent init.sh
  need_absent .agent/adr
  need_one_commit
  need_grep AGENTS.md '.agent/TASK.md' -qF
  need_grep AGENTS.md '.agent/NOTES.md' -qF
  need_grep AGENTS.md 'docs/adr/decisions.md' -qF
  need_grep AGENTS.md '.agent/knowledge/' -qF
  need_grep AGENTS.md 'Knowledge [Pp]reservation' -qiE
  need_grep .agent/NOTES.md 'docs/adr/decisions.md' -qF
  need_grep .agent/NOTES.md 'Active Contracts' -qF
  need_grep AGENTS.md 'npm test' -qF
  need_clean_smoke_test
  need_grep AGENTS.md 'Technical English' -qiF
  need_grep AGENTS.md 'INVARIANT:' -qF
  need_grep AGENTS.md 'circuit breaker' -qiE
  need_grep AGENTS.md 'Consultative Dependency' -qiF
  need_grep AGENTS.md 'Dependency & Runtime Versioning' -qiF
  need_grep AGENTS.md 'LTS' -qiF
  need_grep AGENTS.md 'cognitive complexity' -qiF
  need_grep AGENTS.md 'readme-standard' -qF
  need_grep .agent/TASK.md 'readme-standard' -qF
  assert_product_readme
  need_grep .gitignore '.env' -qF
  need_grep .gitignore '!.env.example' -qF
  need_grep .gitignore '.maestri/' -qF
  need_grep .gitignore 'tsbuildinfo' -qF
  need_grep .gitignore '.agent/.cache/' -qF
  if grep -qiE 'Checklist de adaptação|Adaptation checklist' "$ROOT/AGENTS.md"; then
    fail "adaptation checklist leaked into generated AGENTS.md"
  fi
}

assert_greenfield() {
  assert_greenfield_base
  need_file .agent/ECOSYSTEM.md
  need_grep AGENTS.md '.agent/ECOSYSTEM.md' -qF
  need_grep .agent/ECOSYSTEM.md 'Repository Topology Matrix' -qF
}

assert_greenfield_standalone() {
  assert_greenfield_base
  need_absent .agent/ECOSYSTEM.md
  if grep -qF '.agent/ECOSYSTEM.md' "$ROOT/AGENTS.md"; then
    fail ".agent/ECOSYSTEM.md reference found in AGENTS.md for standalone mode"
  fi
}

assert_brownfield() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/INVARIANTS.md
  need_file .agent/ECOSYSTEM.md
  need_file .agent/knowledge/000-schema.md
  need_file .agent/knowledge/k-000-template.md
  need_file .agent/knowledge/k-001-characterization-test-state-leakage.md
  need_file docs/adr/decisions.md
  need_file .agent/TASK.md
  need_file .agent/NOTES.md
  need_file .agent/ARCHIVE.md
  need_grep .agent/TASK.md 'Task \[00\.1\]: Project Discovery and Context Mapping' -qE
  need_absent .agent/adr
  need_grep AGENTS.md '.agent/INVARIANTS.md' -qF
  need_grep AGENTS.md '.agent/ECOSYSTEM.md' -qF
  need_grep AGENTS.md '.agent/knowledge/' -qF
  need_grep AGENTS.md 'Knowledge [Pp]reservation' -qiE
  need_grep .agent/knowledge/k-001-characterization-test-state-leakage.md 'characterization' -qiE
  need_grep .agent/knowledge/k-001-characterization-test-state-leakage.md 'detectOpenHandles' -qF
  need_grep .agent/ECOSYSTEM.md 'Repository Topology Matrix' -qF
  need_grep AGENTS.md 'characteriz|caracteriza' -qiE
  need_grep AGENTS.md 'Technical English' -qiF
  need_grep AGENTS.md 'INVARIANT:' -qF
  need_grep AGENTS.md 'git push' -qiF
  need_grep AGENTS.md 'Consultative Dependencies' -qiF
  need_grep AGENTS.md 'Stable & LTS Versioning' -qiF
  need_grep AGENTS.md 'readme-standard' -qF
  need_grep .agent/TASK.md 'readme-standard' -qF
  need_grep .agent/INVARIANTS.md 'Chesterton' -qF
}

assert_brownfield_stealth() {
  assert_brownfield
  need_grep AGENTS.md 'Enterprise / Local-Only Mode Active' -qF
  need_grep AGENTS.md 'NEVER STAGE OR COMMIT' -qF
  need_file .git/info/exclude
  need_grep .git/info/exclude '^/AGENTS.md$' -qE
  need_grep .git/info/exclude '^/\.agent/$' -qE
  local status_output
  status_output="$(git -C "$ROOT" status --porcelain)"
  [ -z "$status_output" ] || fail "git status is not clean in stealth mode: $status_output"
}

assert_blackbox() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/ENDPOINTS.md
  need_file .agent/knowledge/000-schema.md
  need_file .agent/knowledge/k-000-template.md
  need_file .agent/knowledge/k-001-soft-200-session-expiry-detection.md
  need_file .agent/skills/reverse-engineering/SKILL.md
  need_file docs/adr/decisions.md
  need_file .agent/TASK.md
  need_file .agent/NOTES.md
  need_file .agent/ARCHIVE.md
  need_grep .agent/TASK.md 'Task \[00\.1\]: Environment Setup and Authentication/Session Mapping' -qE
  need_absent package.json
  need_absent tests/smoke.test.js
  need_file tests/smoke.sh
  [ -x "$ROOT/tests/smoke.sh" ] || fail "tests/smoke.sh is not executable"
  need_file .env.example
  need_file .gitignore
  need_dir .git
  need_absent init.sh
  need_absent .agent/adr
  need_one_commit
  need_grep AGENTS.md 'git push' -qiF
  need_grep AGENTS.md 'Technical English' -qiF
  need_grep AGENTS.md 'INVARIANT:' -qF
  need_grep AGENTS.md '.agent/knowledge/' -qF
  need_grep AGENTS.md 'Knowledge [Pp]reservation' -qiE
  need_grep .agent/knowledge/k-001-soft-200-session-expiry-detection.md 'SessionExpiredError' -qF
  need_grep .agent/knowledge/k-001-soft-200-session-expiry-detection.md 'Soft 200' -qF
  need_grep AGENTS.md 'fixture' -qiE
  need_grep AGENTS.md 'readme-standard' -qF
  need_grep .agent/TASK.md 'readme-standard' -qF
  assert_product_readme
  need_grep AGENTS.md './tests/smoke.sh' -qF
  ( cd "$ROOT" && ./tests/smoke.sh ) || fail "smoke test failed via ./tests/smoke.sh in $ROOT"
  need_grep .gitignore '.env' -qF
  need_grep .gitignore '*.har' -qF
  need_grep .gitignore 'tests/fixtures/real/' -qF
  need_grep .gitignore '.maestri/' -qF
  need_grep .gitignore '*.tsbuildinfo' -qF
  need_grep .gitignore '.agent/.cache/' -qF
  need_grep .agent/ENDPOINTS.md '$TARGET_SESSION_COOKIE' -qF
  if grep -RIE --exclude-dir=.git 'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.' "$ROOT"; then
    fail "JWT-like token found in scaffold"
  fi
}

assert_infra() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/SERVICES.md
  need_file .agent/ECOSYSTEM.md
  need_file .agent/knowledge/000-schema.md
  need_file .agent/knowledge/k-000-template.md
  need_file .agent/knowledge/k-001-docker-bind-mount-permissions.md
  need_file .agent/knowledge/k-002-healthcheck-logging-contract.md
  need_file .agent/skills/compose-service/SKILL.md
  need_file .agent/TASK.md
  need_file .agent/NOTES.md
  need_file .agent/ARCHIVE.md
  need_grep .agent/TASK.md 'Task \[00\.1\]: Map Topology and Provision Baseline Services' -qE
  need_file .env.example
  need_file .gitignore
  need_grep .gitignore '.maestri/' -qF
  need_grep .gitignore '.agent/.cache/' -qF
  need_file compose.yaml.example
  need_dir docs
  need_file docs/README.md
  need_file docs/adr/decisions.md
  need_file docs/incidents/README.md
  need_file docs/incidents/000-template.md
  need_file docs/architecture/000-template.md
  need_dir .git
  need_absent init.sh
  need_absent .agent/adr
  need_one_commit
  need_grep docs/README.md 'author_type' -qF
  need_grep docs/incidents/README.md 'Tier 1' -qF
  need_grep docs/incidents/000-template.md 'author_type' -qF
  need_grep AGENTS.md 'down -v' -qF
  need_grep AGENTS.md 'Technical English' -qiF
  need_grep AGENTS.md 'INVARIANT:' -qF
  need_grep AGENTS.md 'docs/adr/decisions.md' -qF
  need_grep AGENTS.md '.agent/ECOSYSTEM.md' -qF
  need_grep AGENTS.md '.agent/knowledge/' -qF
  need_grep AGENTS.md 'Knowledge [Pp]reservation' -qiE
  need_grep .agent/knowledge/k-001-docker-bind-mount-permissions.md 'Permission denied' -qF
  need_grep .agent/knowledge/k-002-healthcheck-logging-contract.md 'healthz' -qF
  need_grep .agent/skills/compose-service/SKILL.md 'healthz' -qF
  need_grep .agent/skills/compose-service/SKILL.md 'Probe Log Discarding' -qF
  need_grep .agent/ECOSYSTEM.md 'Repository Topology Matrix' -qF
  need_grep AGENTS.md ':latest' -qF
  need_grep AGENTS.md 'healthcheck' -qF
  need_grep AGENTS.md 'readme-standard' -qF
  need_grep .agent/TASK.md 'readme-standard' -qF
  assert_product_readme
  local healthcheck_count
  healthcheck_count="$(grep -c '^    healthcheck:' "$ROOT/compose.yaml.example" || true)"
  [ "$healthcheck_count" -ge 2 ] || fail "expected at least 2 healthchecks in compose.yaml.example, got $healthcheck_count"
  if grep -qE 'image:[[:space:]]*[^[:space:]]+:latest' "$ROOT/compose.yaml.example"; then
    fail ":latest image tag found in compose.yaml.example"
  fi
  if command -v docker >/dev/null 2>&1; then
    docker compose --env-file "$ROOT/.env.example" -f "$ROOT/compose.yaml.example" config --quiet
  else
    echo "⚠️  docker command not found; skipping compose config validation on $(uname -s)"
  fi
}

assert_baremetal() {
  need_file AGENTS.md
  need_dir .agent
  need_file .agent/BASELINE.md
  need_file .agent/INVARIANTS.md
  need_file .agent/TUNINGS.md
  need_file .agent/knowledge/000-schema.md
  need_file .agent/knowledge/k-000-template.md
  need_file .agent/knowledge/k-001-bash-parameter-expansion-braces.md
  need_file .agent/knowledge/k-002-sysctl-persistence-systemd.md
  need_file .agent/skills/baremetal-tuning/SKILL.md
  need_file .agent/TASK.md
  need_file .agent/NOTES.md
  need_file .agent/ARCHIVE.md
  need_grep .agent/TASK.md 'Task \[00\.1\]: Baseline System Audit & Performance Discovery' -qE
  need_absent package.json
  need_absent tests/smoke.test.js
  need_file tests/smoke.sh
  [ -x "$ROOT/tests/smoke.sh" ] || fail "tests/smoke.sh is not executable"
  need_dir docs
  need_file docs/adr/decisions.md
  need_file benchmarks/README.md
  need_dir benchmarks/scripts
  need_file benchmarks/scripts/bench-cpu.sh
  need_file benchmarks/scripts/bench-io.sh
  need_file benchmarks/scripts/bench-latency.sh
  need_file benchmarks/scripts/monitor-thermals.sh
  need_file benchmarks/scripts/stream-telemetry.sh
  [ -x "$ROOT/benchmarks/scripts/stream-telemetry.sh" ] || fail "benchmarks/scripts/stream-telemetry.sh is not executable"
  need_file .env.example
  need_file .gitignore
  need_dir .git
  need_absent init.sh
  need_absent .agent/adr
  need_one_commit
  need_grep AGENTS.md 'Rollback-First' -qiE
  need_grep AGENTS.md 'Technical English' -qiF
  need_grep AGENTS.md 'INVARIANT:' -qF
  need_grep AGENTS.md 'docs/adr/decisions.md' -qF
  need_grep .agent/NOTES.md 'docs/adr/decisions.md' -qF
  need_grep AGENTS.md '.agent/knowledge/' -qF
  need_grep AGENTS.md 'Knowledge [Pp]reservation' -qiE
  need_grep .agent/knowledge/k-001-bash-parameter-expansion-braces.md 'parameter expansion' -qiF
  need_grep .agent/knowledge/k-002-sysctl-persistence-systemd.md 'sysctl' -qF
  need_grep AGENTS.md 'sudo' -qiF
  need_grep AGENTS.md 'readme-standard' -qF
  need_grep .agent/TASK.md 'readme-standard' -qF
  assert_product_readme
  need_grep AGENTS.md './tests/smoke.sh' -qF
  ( cd "$ROOT" && ./tests/smoke.sh ) || fail "smoke test failed via ./tests/smoke.sh in $ROOT"
  need_grep .env.example 'VECTOR_HOST' -qF
  need_grep .env.example 'VECTOR_ENABLED' -qF
  need_grep benchmarks/README.md 'VECTOR_HOST' -qF
  need_grep benchmarks/README.md 'VictoriaLogs' -qF
  need_grep .gitignore '.backups/' -qF
  need_grep .gitignore '.maestri/' -qF
  need_grep .gitignore 'benchmarks/runs/' -qF
  need_grep .gitignore '*.raw' -qF
  need_grep .gitignore '.agent/.cache/' -qF
  need_grep .agent/TUNINGS.md 'Registry' -qiE
  need_grep .agent/BASELINE.md 'Baseline' -qiE
  need_grep .agent/INVARIANTS.md 'Chesterton' -qF
}

case "$KIND" in
  greenfield) assert_greenfield ;;
  greenfield-standalone) assert_greenfield_standalone ;;
  brownfield) assert_brownfield ;;
  brownfield-stealth) assert_brownfield_stealth ;;
  blackbox) assert_blackbox ;;
  infra) assert_infra ;;
  baremetal) assert_baremetal ;;
  *)
    echo "Unknown starter kind: $KIND" >&2
    exit 2
    ;;
esac

echo "✅ $KIND starter contracts passed ($ROOT)"
