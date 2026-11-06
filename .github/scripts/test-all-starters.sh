#!/usr/bin/env bash
# ==============================================================================
# Unified Starter Test Runner Script
# Executes hermetic scaffolding, idempotent reinstallations, and contract
# assertions for all 5 starter templates locally or in CI.
#
# Usage:
#   .github/scripts/test-all-starters.sh [all|drift|greenfield|brownfield|blackbox|infra|baremetal]
# ==============================================================================
set -euo pipefail

TARGET="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Support local workspace fallback or CI GITHUB_WORKSPACE
export TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-${GITHUB_WORKSPACE:-$REPO_ROOT}}"

# Hermetic Git author identity for scaffolding test commits
export GIT_AUTHOR_NAME="${GIT_AUTHOR_NAME:-Antigravity Lead}"
export GIT_AUTHOR_EMAIL="${GIT_AUTHOR_EMAIL:-lead@template-hub.internal}"
export GIT_COMMITTER_NAME="${GIT_COMMITTER_NAME:-Antigravity Lead}"
export GIT_COMMITTER_EMAIL="${GIT_COMMITTER_EMAIL:-lead@template-hub.internal}"

ASSERT_SCRIPT="$SCRIPT_DIR/assert-starter-contracts.sh"
if [ ! -x "$ASSERT_SCRIPT" ]; then
  chmod +x "$ASSERT_SCRIPT"
fi

TMP_BASE="$(mktemp -d "${TMPDIR:-/tmp}/test-all-starters.XXXXXX")"
trap 'rm -rf "$TMP_BASE"' EXIT INT TERM

log_info() {
  echo -e "\n\033[1;34m==>\033[0m \033[1m$*\033[0m"
}

log_success() {
  echo -e "\033[1;32m✓\033[0m $*"
}

resolve_branch_ref() {
  local branch="$1"
  if git -C "$REPO_ROOT" rev-parse --verify "refs/heads/$branch" >/dev/null 2>&1; then
    echo "$branch"
  elif git -C "$REPO_ROOT" rev-parse --verify "refs/remotes/origin/$branch" >/dev/null 2>&1; then
    echo "origin/$branch"
  elif git -C "$REPO_ROOT" rev-parse --verify "$branch" >/dev/null 2>&1; then
    echo "$branch"
  else
    echo "❌ Cannot resolve branch ref for $branch" >&2
    return 1
  fi
}

extract_branch_file() {
  local branch="$1"
  local file="$2"
  local dest="$3"
  local ref
  ref="$(resolve_branch_ref "$branch")"
  git -C "$REPO_ROOT" show "$ref:$file" > "$dest"
}

extract_branch_archive() {
  local branch="$1"
  local dest="$2"
  local ref
  ref="$(resolve_branch_ref "$branch")"
  mkdir -p "$dest"
  git -C "$REPO_ROOT" archive "$ref" | tar -x -C "$dest"
}

assert_cli_flags() {
  local script_name="$1"
  local script_path="$2"
  log_info "Verifying CLI flags for $script_name..."

  local help_short help_long
  help_short="$("$script_path" -h)"
  if ! echo "$help_short" | grep -qi "Usage:"; then
    echo "❌ $script_name -h did not output usage string" >&2
    return 1
  fi

  help_long="$("$script_path" --help)"
  if ! echo "$help_long" | grep -qi "Usage:"; then
    echo "❌ $script_name --help did not output usage string" >&2
    return 1
  fi

  log_success "$script_name CLI flags (-h, --help) validated"
}

test_greenfield() {
  log_info "Testing Greenfield starter scaffolding & contracts..."
  local target_dir="$TMP_BASE/greenfield"
  local force_dir="$TMP_BASE/greenfield-force"
  local standalone_dir="$TMP_BASE/greenfield-standalone"
  local init_script="$TMP_BASE/init-greenfield.sh"

  extract_branch_file greenfield init.sh "$init_script"
  chmod +x "$init_script"
  assert_cli_flags "greenfield init.sh" "$init_script"

  log_info "Testing Greenfield starter with force flag (-f)..."
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -f "$force_dir"
  "$ASSERT_SCRIPT" greenfield "$force_dir"
  log_success "Greenfield force flag (-f) passed all assertions"

  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y "$target_dir"
  "$ASSERT_SCRIPT" greenfield "$target_dir"
  log_success "Greenfield standard starter passed all assertions"

  log_info "Testing Greenfield starter in Standalone Mode (--standalone)..."
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y --standalone "$standalone_dir"
  rm -f "$init_script"

  "$ASSERT_SCRIPT" greenfield-standalone "$standalone_dir"
  log_success "Greenfield standalone starter passed all assertions"
}

test_brownfield() {
  log_info "Testing Brownfield starter (standard injection & idempotency)..."
  local src_dir="$TMP_BASE/brownfield-src"
  local target_dir="$TMP_BASE/brownfield-standard"
  local force_dir="$TMP_BASE/brownfield-force"
  local stealth_dir="$TMP_BASE/brownfield-stealth"

  extract_branch_archive brownfield "$src_dir"
  chmod +x "$src_dir/install.sh"
  assert_cli_flags "brownfield install.sh" "$src_dir/install.sh"

  log_info "Testing Brownfield starter with force flag (-f)..."
  "$src_dir/install.sh" -f "$force_dir"
  "$ASSERT_SCRIPT" brownfield "$force_dir"
  log_success "Brownfield force flag (-f) passed all assertions"

  # Initial injection
  "$src_dir/install.sh" -y "$target_dir"
  # Idempotent re-run
  "$src_dir/install.sh" -y "$target_dir"
  "$ASSERT_SCRIPT" brownfield "$target_dir"
  log_success "Brownfield standard injection & idempotency passed all assertions"

  log_info "Testing Brownfield starter in Stealth Mode (--local-only)..."
  mkdir -p "$stealth_dir"
  git -C "$stealth_dir" init -q
  touch "$stealth_dir/index.js"
  git -C "$stealth_dir" add index.js
  git -C "$stealth_dir" commit -q -m "feat(repo): initial enterprise commit"

  "$src_dir/install.sh" -y --local-only "$stealth_dir"
  "$ASSERT_SCRIPT" brownfield-stealth "$stealth_dir"
  log_success "Brownfield stealth mode passed all assertions"
}

test_blackbox() {
  log_info "Testing Blackbox starter scaffolding & contracts..."
  local target_dir="$TMP_BASE/blackbox"
  local force_dir="$TMP_BASE/blackbox-force"
  local init_script="$TMP_BASE/init-blackbox.sh"

  extract_branch_file blackbox init.sh "$init_script"
  chmod +x "$init_script"
  assert_cli_flags "blackbox init.sh" "$init_script"

  log_info "Testing Blackbox starter with force flag (-f)..."
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -f "$force_dir"
  "$ASSERT_SCRIPT" blackbox "$force_dir"
  log_success "Blackbox force flag (-f) passed all assertions"

  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y "$target_dir"
  rm -f "$init_script"

  "$ASSERT_SCRIPT" blackbox "$target_dir"
  log_success "Blackbox starter passed all assertions"
}

test_infra() {
  log_info "Testing Infra starter scaffolding & contracts..."
  local target_dir="$TMP_BASE/infra"
  local force_dir="$TMP_BASE/infra-force"
  local init_script="$TMP_BASE/init-infra.sh"

  extract_branch_file infra init.sh "$init_script"
  chmod +x "$init_script"
  assert_cli_flags "infra init.sh" "$init_script"

  log_info "Testing Infra starter with force flag (-f)..."
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -f "$force_dir"
  "$ASSERT_SCRIPT" infra "$force_dir"
  log_success "Infra force flag (-f) passed all assertions"

  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y "$target_dir"
  rm -f "$init_script"

  "$ASSERT_SCRIPT" infra "$target_dir"
  log_success "Infra starter passed all assertions"
}

test_baremetal() {
  log_info "Testing Baremetal starter scaffolding & contracts..."
  local target_dir="$TMP_BASE/baremetal"
  local force_dir="$TMP_BASE/baremetal-force"
  local init_script="$TMP_BASE/init-baremetal.sh"

  extract_branch_file baremetal init.sh "$init_script"
  chmod +x "$init_script"
  assert_cli_flags "baremetal init.sh" "$init_script"

  log_info "Testing Baremetal starter with force flag (-f)..."
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -f "$force_dir"
  "$ASSERT_SCRIPT" baremetal "$force_dir"
  log_success "Baremetal force flag (-f) passed all assertions"

  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y "$target_dir"
  rm -f "$init_script"

  "$ASSERT_SCRIPT" baremetal "$target_dir"
  log_success "Baremetal starter passed all assertions"
}

check_drift() {
  local drift_script="$SCRIPT_DIR/check-branch-drift.sh"
  if [ -f "$drift_script" ]; then
    log_info "Auditing inter-branch governance & drift..."
    chmod +x "$drift_script"
    "$drift_script"
    log_success "Inter-branch governance audit passed"
  fi
}

test_microcontract_runner() {
  local runner_script="$SCRIPT_DIR/verify-microcontract.sh"
  if [ -f "$runner_script" ]; then
    log_info "Verifying Micro-Contract & Worktree Validation Runner..."
    chmod +x "$runner_script"
    assert_cli_flags "verify-microcontract.sh" "$runner_script"
    "$runner_script"
    log_success "Micro-Contract runner validated successfully"
  fi
}

case "$TARGET" in
  all)
    check_drift
    test_microcontract_runner
    test_greenfield
    test_brownfield
    test_blackbox
    test_infra
    test_baremetal
    log_info "All 5 starter templates and micro-contract guardrails validated successfully!"
    ;;
  drift)
    check_drift
    ;;
  microcontract)
    test_microcontract_runner
    ;;
  greenfield)
    test_greenfield
    ;;
  brownfield)
    test_brownfield
    ;;
  blackbox)
    test_blackbox
    ;;
  infra)
    test_infra
    ;;
  baremetal)
    test_baremetal
    ;;
  *)
    echo "❌ Unknown starter target: $TARGET" >&2
    echo "Usage: $0 [all|drift|microcontract|greenfield|brownfield|blackbox|infra|baremetal]" >&2
    exit 2
    ;;
esac
