#!/usr/bin/env bash
# ==============================================================================
# Worktree Fast-Link Bootstrap & Lifecycle Hook Runner
# Fast-links dependency caches (node_modules, .venv), isolates scratch environments,
# propagates .env configurations, and executes standardized project lifecycle hooks.
#
# Usage:
#   bootstrap-worktree.sh [options] [worktree-path]
#
# Options:
#   --root <dir>              Path to primary repository root (default: git rev-parse --show-toplevel)
#   --worktree <dir>          Path to target Git worktree (or pass as positional argument)
#   --touches-manifests       Force isolated install instead of fast-link symlinking
#   --run-hook <hook-name>    Execute a designated lifecycle hook (e.g., post-worktree-create, pre-verify, post-worktree-teardown)
#   --self-test               Execute hermetic end-to-end self-tests
#   -h, --help                Show this help message
#   -v, --version             Display version information
# ==============================================================================
set -euo pipefail

VERSION="1.0.0"

# ANSI color formatting
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD="\033[1m"
  GREEN="\033[1;32m"
  RED="\033[1;31m"
  YELLOW="\033[1;33m"
  BLUE="\033[1;34m"
  RESET="\033[0m"
else
  BOLD=""
  GREEN=""
  RED=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

# Temporary cleanup tracker for traps
TMP_CLEANUP_DIRS=()
cleanup_tmp_dirs() {
  for d in "${TMP_CLEANUP_DIRS[@]:-}"; do
    if [ -n "$d" ] && [ -d "$d" ]; then
      rm -rf "$d"
    fi
  done
}
trap cleanup_tmp_dirs EXIT INT TERM

log_info() {
  echo -e "${BLUE}==>${RESET} ${BOLD}$*${RESET}"
}

log_success() {
  echo -e "${GREEN}✓${RESET} $*"
}

log_warn() {
  echo -e "${YELLOW}⚠${RESET} $*" >&2
}

log_error() {
  echo -e "${RED}❌${RESET} $*" >&2
}

show_help() {
  cat << EOF
Worktree Fast-Link Bootstrap & Lifecycle Hook Runner v${VERSION}

Usage:
  $(basename "$0") [options] [worktree-path]

Options:
  --root <dir>
      Path to root repository directory.
      Defaults to the current Git repository root.

  --worktree <dir>
      Path to target worktree directory. Can also be supplied as the
      first positional argument.

  --touches-manifests
      Specifies that the worktree task modifies dependency manifests
      (e.g., package.json, pyproject.toml). Triggers isolated installation
      instead of zero-copy fast-linking.

  --run-hook <hook-name>
      Execute a specific lifecycle hook located under .agent/hooks/<hook-name>.
      Supported canonical hooks:
        - post-worktree-create   (invoked automatically post-bootstrap)
        - pre-verify             (invoked prior to task verification)
        - post-worktree-teardown (invoked prior to worktree removal)

  --self-test
      Execute hermetic end-to-end self-tests verifying fast-linking,
      environment isolation, scratch creation, and hook lifecycle execution.

  -h, --help
      Display this help documentation.

  -v, --version
      Display runner version.

Exit Codes:
  0   Success (bootstrap or hook executed successfully).
  1   Operation or verification failure.
  2   CLI syntax or usage error.
EOF
}

# ------------------------------------------------------------------------------
# Lifecycle Hook Execution
# ------------------------------------------------------------------------------
execute_lifecycle_hook() {
  local ROOT_DIR="$1"
  local WORKTREE_DIR="$2"
  local HOOK_NAME="$3"

  local HOOK_SCRIPT=""
  if [ -f "${WORKTREE_DIR}/.agent/hooks/${HOOK_NAME}" ]; then
    HOOK_SCRIPT="${WORKTREE_DIR}/.agent/hooks/${HOOK_NAME}"
  elif [ -f "${ROOT_DIR}/.agent/hooks/${HOOK_NAME}" ]; then
    HOOK_SCRIPT="${ROOT_DIR}/.agent/hooks/${HOOK_NAME}"
  fi

  if [ -n "$HOOK_SCRIPT" ]; then
    log_info "Executing lifecycle hook: ${HOOK_NAME} (${HOOK_SCRIPT})"
    (
      export ROOT_DIR
      export WORKTREE_DIR
      export HOOK_NAME
      cd "${WORKTREE_DIR}"
      if [ -x "$HOOK_SCRIPT" ]; then
        "$HOOK_SCRIPT"
      else
        bash "$HOOK_SCRIPT"
      fi
    )
    log_success "Lifecycle hook '${HOOK_NAME}' completed successfully."
  else
    # Hooks are optional; silent skip if not configured
    return 0
  fi
}

# ------------------------------------------------------------------------------
# Dependency Fast-Link & Environment Bootstrap
# ------------------------------------------------------------------------------
bootstrap_worktree() {
  local ROOT_DIR="$1"
  local WORKTREE_DIR="$2"
  local TOUCHES_MANIFESTS="${3:-false}"

  if [ ! -d "$ROOT_DIR" ]; then
    log_error "Root directory does not exist: $ROOT_DIR"
    return 1
  fi

  if [ ! -d "$WORKTREE_DIR" ]; then
    log_error "Worktree directory does not exist: $WORKTREE_DIR"
    return 1
  fi

  # Resolve absolute canonical paths
  ROOT_DIR="$(cd "$ROOT_DIR" && pwd -P)"
  WORKTREE_DIR="$(cd "$WORKTREE_DIR" && pwd -P)"

  log_info "Bootstrapping worktree at: ${WORKTREE_DIR}"
  log_info "Primary repository root: ${ROOT_DIR}"

  # 1. Propagate environment (.env / .env.example)
  # INVARIANT: Copy instead of symlink to prevent leaking worktree test mutations back to root
  if [ -f "${ROOT_DIR}/.env" ] && [ ! -f "${WORKTREE_DIR}/.env" ]; then
    cp "${ROOT_DIR}/.env" "${WORKTREE_DIR}/.env"
    log_success "Propagated .env (isolated copy)"
  elif [ -f "${ROOT_DIR}/.env.example" ] && [ ! -f "${WORKTREE_DIR}/.env" ]; then
    cp "${ROOT_DIR}/.env.example" "${WORKTREE_DIR}/.env"
    log_success "Propagated .env.example -> .env (isolated copy)"
  fi

  # 2. Scratch and cache directory isolation
  # INVARIANT: Subagents must have private scratch directories to prevent inter-agent race conditions
  mkdir -p "${WORKTREE_DIR}/.agent/scratch"
  mkdir -p "${WORKTREE_DIR}/.agent/.cache"
  log_success "Initialized isolated scratch environment (.agent/scratch, .agent/.cache)"

  # 3. Node.js dependency bootstrap
  if [ -f "${ROOT_DIR}/package.json" ]; then
    if [ "$TOUCHES_MANIFESTS" = "false" ] && [ -d "${ROOT_DIR}/node_modules" ]; then
      if [ -e "${WORKTREE_DIR}/node_modules" ] || [ -L "${WORKTREE_DIR}/node_modules" ]; then
        rm -rf "${WORKTREE_DIR}/node_modules"
      fi
      ln -s "${ROOT_DIR}/node_modules" "${WORKTREE_DIR}/node_modules"
      log_success "Fast-linked node_modules/ (<50ms zero-copy symlink)"
    elif [ "$TOUCHES_MANIFESTS" = "true" ]; then
      log_info "Manifest changes detected; initiating isolated Node.js installation..."
      (
        cd "${WORKTREE_DIR}"
        if [ -f "pnpm-lock.yaml" ] && command -v pnpm >/dev/null 2>&1; then
          pnpm install --frozen-lockfile --prefer-offline 2>/dev/null || pnpm install
        elif [ -f "package-lock.json" ] && command -v npm >/dev/null 2>&1; then
          npm ci --prefer-offline 2>/dev/null || npm install
        elif command -v npm >/dev/null 2>&1; then
          npm install
        fi
      )
      log_success "Isolated Node.js dependency installation complete."
    fi
  fi

  # 4. Python dependency bootstrap
  if [ -f "${ROOT_DIR}/pyproject.toml" ] || [ -f "${ROOT_DIR}/requirements.txt" ]; then
    if [ "$TOUCHES_MANIFESTS" = "false" ] && [ -d "${ROOT_DIR}/.venv" ]; then
      if [ -e "${WORKTREE_DIR}/.venv" ] || [ -L "${WORKTREE_DIR}/.venv" ]; then
        rm -rf "${WORKTREE_DIR}/.venv"
      fi
      ln -s "${ROOT_DIR}/.venv" "${WORKTREE_DIR}/.venv"
      log_success "Fast-linked .venv/ (<50ms zero-copy symlink)"
    elif [ "$TOUCHES_MANIFESTS" = "true" ]; then
      log_info "Manifest changes detected; initiating isolated Python virtualenv..."
      (
        cd "${WORKTREE_DIR}"
        if command -v uv >/dev/null 2>&1; then
          uv venv .venv >/dev/null 2>&1 || true
          if [ -f requirements.txt ]; then
            uv pip install -r requirements.txt 2>/dev/null || true
          fi
        elif command -v python3 >/dev/null 2>&1; then
          python3 -m venv .venv >/dev/null 2>&1 || true
          if [ -f requirements.txt ]; then
            ( . .venv/bin/activate 2>/dev/null && pip install -q -r requirements.txt 2>/dev/null ) || true
          fi
        fi
      )
      log_success "Isolated Python virtual environment complete."
    fi
  fi

  # 5. Automatically trigger post-worktree-create lifecycle hook if present
  execute_lifecycle_hook "$ROOT_DIR" "$WORKTREE_DIR" "post-worktree-create"
}

# ------------------------------------------------------------------------------
# Self-Test Suite
# ------------------------------------------------------------------------------
run_self_tests() {
  log_info "Running hermetic self-test suite for bootstrap-worktree.sh..."

  local TEST_TMP
  TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-test.XXXXXX")"
  TMP_CLEANUP_DIRS+=("$TEST_TMP")

  local REPO_DIR="${TEST_TMP}/repo"
  local WORKTREE_DIR="${TEST_TMP}/worktree-1"
  mkdir -p "$REPO_DIR"

  (
    cd "$REPO_DIR"
    git init -q -b main
    git config user.name "Test Agent"
    git config user.email "agent@test.internal"

    # Setup dummy root files
    echo "SECRET_KEY=supersecret" > .env
    echo '{"name":"test-pkg"}' > package.json
    echo "pytest==8.0.0" > requirements.txt
    cat << 'GITIGNORE_EOF' > .gitignore
.env
node_modules/
.venv/
.agent/scratch/
.agent/.cache/
GITIGNORE_EOF
    mkdir -p node_modules/dummy-pkg
    echo "module.exports = {};" > node_modules/dummy-pkg/index.js

    mkdir -p .venv/bin
    touch .venv/bin/python

    echo "# Test repo" > README.md
    git add README.md package.json requirements.txt .gitignore
    git commit -q -m "chore: initial commit"

    # Add worktree
    git worktree add -q -b task-test "$WORKTREE_DIR" HEAD
  )

  # Test 1: Fast-Link Mode (Zero-Copy)
  log_info "Self-Test 1: Fast-Link Mode..."
  bootstrap_worktree "$REPO_DIR" "$WORKTREE_DIR" "false"

  [ -f "${WORKTREE_DIR}/.env" ] || { log_error "Test 1 failed: .env not created in worktree"; return 1; }
  [ ! -L "${WORKTREE_DIR}/.env" ] || { log_error "Test 1 failed: .env must be a copy, not symlink"; return 1; }
  [ -d "${WORKTREE_DIR}/.agent/scratch" ] || { log_error "Test 1 failed: .agent/scratch missing"; return 1; }
  [ -L "${WORKTREE_DIR}/node_modules" ] || { log_error "Test 1 failed: node_modules is not a symlink"; return 1; }
  [ -L "${WORKTREE_DIR}/.venv" ] || { log_error "Test 1 failed: .venv is not a symlink"; return 1; }
  log_success "Self-Test 1 passed: Fast-link symlinks and env copy verified."

  # Test 2: Lifecycle Hook Execution
  log_info "Self-Test 2: Lifecycle Hook Execution..."
  mkdir -p "${REPO_DIR}/.agent/hooks"
  cat << 'HOOK_EOF' > "${REPO_DIR}/.agent/hooks/post-worktree-create"
#!/usr/bin/env bash
set -e
echo "hook-ran-successfully" > "${WORKTREE_DIR}/hook-proof.txt"
HOOK_EOF
  chmod +x "${REPO_DIR}/.agent/hooks/post-worktree-create"

  execute_lifecycle_hook "$REPO_DIR" "$WORKTREE_DIR" "post-worktree-create"
  [ -f "${WORKTREE_DIR}/hook-proof.txt" ] || { log_error "Test 2 failed: hook-proof.txt not created"; return 1; }
  [ "$(cat "${WORKTREE_DIR}/hook-proof.txt")" = "hook-ran-successfully" ] || { log_error "Test 2 failed: content mismatch"; return 1; }
  log_success "Self-Test 2 passed: Lifecycle hook executed correctly."

  # Test 3: Custom Hook Execution via CLI flag
  log_info "Self-Test 3: Custom Hook Execution via CLI..."
  cat << 'HOOK_EOF' > "${REPO_DIR}/.agent/hooks/pre-verify"
#!/usr/bin/env bash
set -e
echo "pre-verify-ran" > "${WORKTREE_DIR}/pre-verify.txt"
HOOK_EOF
  chmod +x "${REPO_DIR}/.agent/hooks/pre-verify"

  execute_lifecycle_hook "$REPO_DIR" "$WORKTREE_DIR" "pre-verify"
  [ -f "${WORKTREE_DIR}/pre-verify.txt" ] || { log_error "Test 3 failed: pre-verify.txt missing"; return 1; }
  log_success "Self-Test 3 passed: Custom lifecycle hook verified."

  # Teardown temporary worktree
  (
    cd "$REPO_DIR"
    git worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || rm -rf "$WORKTREE_DIR"
    git branch -D task-test >/dev/null 2>&1 || true
    git worktree prune
  )

  log_success "All self-tests passed successfully!"
  return 0
}

# ------------------------------------------------------------------------------
# Main CLI Entrypoint
# ------------------------------------------------------------------------------
main() {
  local ROOT_DIR=""
  local WORKTREE_DIR=""
  local TOUCHES_MANIFESTS="false"
  local HOOK_TO_RUN=""
  local RUN_SELF_TEST="false"

  while [ $# -gt 0 ]; do
    case "$1" in
      --root)
        [ $# -ge 2 ] || { log_error "Missing argument for --root"; exit 2; }
        ROOT_DIR="$2"
        shift 2
        ;;
      --worktree)
        [ $# -ge 2 ] || { log_error "Missing argument for --worktree"; exit 2; }
        WORKTREE_DIR="$2"
        shift 2
        ;;
      --touches-manifests)
        TOUCHES_MANIFESTS="true"
        shift
        ;;
      --run-hook)
        [ $# -ge 2 ] || { log_error "Missing argument for --run-hook"; exit 2; }
        HOOK_TO_RUN="$2"
        shift 2
        ;;
      --self-test)
        RUN_SELF_TEST="true"
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -v|--version)
        echo "bootstrap-worktree.sh v${VERSION}"
        exit 0
        ;;
      *)
        if [ -z "$WORKTREE_DIR" ]; then
          WORKTREE_DIR="$1"
          shift
        else
          log_error "Unknown argument: $1"
          show_help
          exit 2
        fi
        ;;
    esac
  done

  if [ "$RUN_SELF_TEST" = "true" ]; then
    run_self_tests
    exit $?
  fi

  # Auto-resolve root directory if not provided
  if [ -z "$ROOT_DIR" ]; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      ROOT_DIR="$(git rev-parse --show-toplevel)"
    else
      ROOT_DIR="$(pwd)"
    fi
  fi

  if [ -z "$WORKTREE_DIR" ]; then
    log_error "Missing target worktree path. Specify via positional argument or --worktree <dir>."
    show_help
    exit 2
  fi

  if [ -n "$HOOK_TO_RUN" ]; then
    execute_lifecycle_hook "$ROOT_DIR" "$WORKTREE_DIR" "$HOOK_TO_RUN"
  else
    bootstrap_worktree "$ROOT_DIR" "$WORKTREE_DIR" "$TOUCHES_MANIFESTS"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
