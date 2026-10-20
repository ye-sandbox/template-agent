#!/usr/bin/env bash
# ==============================================================================
# Unified Starter Test Runner Script
# Executes hermetic scaffolding, idempotent reinstallations, and contract
# assertions for all 5 starter templates locally or in CI.
#
# Usage:
#   .github/scripts/test-all-starters.sh [all|greenfield|brownfield|blackbox|infra|baremetal]
# ==============================================================================
set -euo pipefail

TARGET="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Support local workspace fallback or CI GITHUB_WORKSPACE
export TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-${GITHUB_WORKSPACE:-$REPO_ROOT}}"

ASSERT_SCRIPT="$SCRIPT_DIR/assert-starter-contracts.sh"
if [ ! -x "$ASSERT_SCRIPT" ]; then
  chmod +x "$ASSERT_SCRIPT"
fi

TMP_BASE="$(mktemp -d /tmp/test-all-starters.XXXXXX)"
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

test_greenfield() {
  log_info "Testing Greenfield starter scaffolding & contracts..."
  local target_dir="$TMP_BASE/greenfield"
  local standalone_dir="$TMP_BASE/greenfield-standalone"
  local init_script="$TMP_BASE/init-greenfield.sh"

  extract_branch_file greenfield init.sh "$init_script"
  chmod +x "$init_script"
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
  local stealth_dir="$TMP_BASE/brownfield-stealth"

  extract_branch_archive brownfield "$src_dir"
  chmod +x "$src_dir/install.sh"

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
  local init_script="$TMP_BASE/init-blackbox.sh"

  extract_branch_file blackbox init.sh "$init_script"
  chmod +x "$init_script"
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y "$target_dir"
  rm -f "$init_script"

  "$ASSERT_SCRIPT" blackbox "$target_dir"
  log_success "Blackbox starter passed all assertions"
}

test_infra() {
  log_info "Testing Infra starter scaffolding & contracts..."
  local target_dir="$TMP_BASE/infra"
  local init_script="$TMP_BASE/init-infra.sh"

  extract_branch_file infra init.sh "$init_script"
  chmod +x "$init_script"
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y "$target_dir"
  rm -f "$init_script"

  "$ASSERT_SCRIPT" infra "$target_dir"
  log_success "Infra starter passed all assertions"
}

test_baremetal() {
  log_info "Testing Baremetal starter scaffolding & contracts..."
  local target_dir="$TMP_BASE/baremetal"
  local init_script="$TMP_BASE/init-baremetal.sh"

  extract_branch_file baremetal init.sh "$init_script"
  chmod +x "$init_script"
  TEMPLATE_REPO_URL="$TEMPLATE_REPO_URL" "$init_script" -y "$target_dir"
  rm -f "$init_script"

  "$ASSERT_SCRIPT" baremetal "$target_dir"
  log_success "Baremetal starter passed all assertions"
}

case "$TARGET" in
  all)
    test_greenfield
    test_brownfield
    test_blackbox
    test_infra
    test_baremetal
    log_info "All 5 starter templates validated successfully!"
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
    echo "Usage: $0 [all|greenfield|brownfield|blackbox|infra|baremetal]" >&2
    exit 2
    ;;
esac
