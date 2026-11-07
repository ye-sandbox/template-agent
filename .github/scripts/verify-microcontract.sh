#!/usr/bin/env bash
# ==============================================================================
# Micro-Contract & Worktree Validation Runner Script
# Asserts micro-contract keys (Read:, Paths:, Verify:), parallel wave tags
# ([PARALLEL: Wx]), file disjointness, and git worktree blast boundaries.
#
# Usage:
#   verify-microcontract.sh [command] [options]
#
# Commands:
#   self-test                       Run hermetic end-to-end self-test suite (default if no args)
#   verify-file <file>              Validate all micro-contracts and parallel waves in a task file
#   verify-contract <file|->        Validate a single micro-contract specification snippet or file
#   verify-waves <file>             Validate parallel wave tag disjointness in a task file
#   verify-worktree <worktree> <contract> [--base-ref <ref>] [--run-verify]
#                                   Assert worktree blast boundaries, diff hygiene, and verification
#   -h, --help                      Show this help message
#   -v, --version                   Display version information
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
Micro-Contract & Worktree Validation Runner v${VERSION}

Usage:
  $(basename "$0") [command] [arguments...]

Commands:
  self-test
      Run comprehensive hermetic self-tests for micro-contract parsing,
      wave disjointness, and worktree blast boundary enforcement.
      (Default action when invoked without arguments).

  verify-file <path-to-task-file>
      Parse and validate all micro-contracts in a task file (e.g. .agent/TASK.md).
      Checks for required keys (Read:, Paths:, Verify:), valid role and isolation
      values, and ensures parallel waves [PARALLEL: Wx] have disjoint Paths.

  verify-contract <contract-file | ->
      Validate a single micro-contract snippet (from file or stdin).
      Validates required keys (Read:, Paths:, Verify:) and schema constraints.

  verify-waves <path-to-task-file>
      Assert that all tasks grouped under identical wave tags ([PARALLEL: Wx])
      in the specified task file possess mutually disjoint mutable Paths.

  verify-worktree <worktree-path> <contract-file> [--base-ref <ref>] [--run-verify]
      Inspect an isolated Git worktree before integration:
        - Confirms all modified/added/deleted files fall strictly within whitelisted Paths:
        - Validates Git whitespace and formatting hygiene via 'git diff --check'
        - Optionally executes the 'Verify:' command within the isolated worktree

  -h, --help
      Display this help documentation.

  -v, --version
      Display runner version.

Exit Codes:
  0   All validations and assertions passed successfully.
  1   Validation failure (syntax error, blast radius violation, contract drift).
  2   CLI usage error or invalid arguments.
EOF
}

# ------------------------------------------------------------------------------
# Path Utilities & Collision Detection
# ------------------------------------------------------------------------------

normalize_path() {
  local p="$1"
  p="${p#"${p%%[![:space:]]*}"}" # trim leading whitespace
  p="${p%"${p##*[![:space:]]}"}" # trim trailing whitespace
  p="${p#./}"                    # remove leading ./
  p="${p%/}"                     # remove trailing /
  echo "$p"
}

# Check if path1 collides with or overlaps path2
# Returns 0 if collision detected, 1 otherwise
paths_collide() {
  local a b
  a="$(normalize_path "$1")"
  b="$(normalize_path "$2")"

  [ -z "$a" ] || [ -z "$b" ] && return 1

  # Exact match
  if [ "$a" = "$b" ]; then
    return 0
  fi

  # Directory or prefix overlap: a contains b or b contains a
  if [[ "$b" == "$a/"* ]] || [[ "$a" == "$b/"* ]]; then
    return 0
  fi

  # Wildcard / glob handling (e.g., src/** or src/*)
  local a_clean="${a%\*\*}"
  a_clean="${a_clean%\*}"
  a_clean="${a_clean%/}"

  local b_clean="${b%\*\*}"
  b_clean="${b_clean%\*}"
  b_clean="${b_clean%/}"

  if [ -n "$a_clean" ] && { [ "$b" = "$a_clean" ] || [[ "$b" == "$a_clean/"* ]]; }; then
    return 0
  fi
  if [ -n "$b_clean" ] && { [ "$a" = "$b_clean" ] || [[ "$a" == "$b_clean/"* ]]; }; then
    return 0
  fi

  return 1
}

# Check if a target file matches any pattern in a whitelist of paths
# Returns 0 if matches whitelist, 1 otherwise
path_matches_whitelist() {
  local target="$1"
  shift
  local whitelist=("$@")

  local norm_target
  norm_target="$(normalize_path "$target")"

  for item in "${whitelist[@]}"; do
    local norm_item
    norm_item="$(normalize_path "$item")"
    [ -z "$norm_item" ] && continue

    # Exact match
    if [ "$norm_target" = "$norm_item" ]; then
      return 0
    fi

    # Subpath of directory in whitelist
    if [[ "$norm_target" == "$norm_item/"* ]]; then
      return 0
    fi

    # Wildcard match (e.g. docs/** or *.md)
    local clean_item="${norm_item%\*\*}"
    clean_item="${clean_item%\*}"
    clean_item="${clean_item%/}"
    if [ -n "$clean_item" ] && [[ "$norm_target" == "$clean_item/"* ]]; then
      return 0
    fi

    # Bash pattern match
    # shellcheck disable=SC2254
    case "$norm_target" in
      $norm_item) return 0 ;;
    esac
  done

  return 1
}

# ------------------------------------------------------------------------------
# Single Micro-Contract Validation
# ------------------------------------------------------------------------------

# Validates a single micro-contract string or file
# Expects either file path or '-' for stdin
validate_single_contract() {
  local src="${1:-}"
  local content

  if [ -z "$src" ]; then
    echo "Usage: $(basename "$0") verify-contract <file|->" >&2
    return 2
  fi

  if [ "$src" = "-" ]; then
    content="$(cat)"
  elif [ -f "$src" ]; then
    content="$(cat "$src")"
  else
    log_error "Contract source file not found: $src"
    return 1
  fi

  local errors=0
  local has_read=false
  local has_paths=false
  local has_verify=false
  local verify_cmd=""
  local role=""
  local isolation=""

  # Check required keys
  if echo "$content" | grep -qE '^[[:space:]]*(-[[:space:]]*)?Read:'; then
    has_read=true
  fi
  if echo "$content" | grep -qE '^[[:space:]]*(-[[:space:]]*)?Paths:'; then
    has_paths=true
  fi
  if echo "$content" | grep -qE '^[[:space:]]*(-[[:space:]]*)?Verify:'; then
    has_verify=true
    verify_cmd="$(echo "$content" | grep -E '^[[:space:]]*(-[[:space:]]*)?Verify:' | head -n1 | sed -E 's/^[[:space:]]*(-[[:space:]]*)?Verify:[[:space:]]*//')"
  fi

  if [ "$has_read" = "false" ]; then
    log_error "Missing required micro-contract key: 'Read:'"
    errors=$((errors + 1))
  fi
  if [ "$has_paths" = "false" ]; then
    log_error "Missing required micro-contract key: 'Paths:'"
    errors=$((errors + 1))
  fi
  if [ "$has_verify" = "false" ]; then
    log_error "Missing required micro-contract key: 'Verify:'"
    errors=$((errors + 1))
  elif [ -z "$verify_cmd" ]; then
    log_error "'Verify:' key is present but specifies an empty command"
    errors=$((errors + 1))
  fi

  # Optional Role check
  if echo "$content" | grep -qE '^[[:space:]]*(-[[:space:]]*)?Role:'; then
    role="$(echo "$content" | grep -E '^[[:space:]]*(-[[:space:]]*)?Role:' | head -n1 | sed -E 's/^[[:space:]]*(-[[:space:]]*)?Role:[[:space:]]*//')"
    role="$(normalize_path "$role")"
    case "$role" in
      Worker|Reviewer|Lead|Orchestrator|Sentinel) ;;
      *)
        log_error "Invalid 'Role:' '$role'. Must be one of: Worker, Reviewer, Lead, Orchestrator, Sentinel"
        errors=$((errors + 1))
        ;;
    esac
  fi

  # Optional Isolation check
  if echo "$content" | grep -qE '^[[:space:]]*(-[[:space:]]*)?Isolation:'; then
    isolation="$(echo "$content" | grep -E '^[[:space:]]*(-[[:space:]]*)?Isolation:' | head -n1 | sed -E 's/^[[:space:]]*(-[[:space:]]*)?Isolation:[[:space:]]*//')"
    isolation="$(normalize_path "$isolation")"
    case "$isolation" in
      worktree|branch|inherit) ;;
      *)
        log_error "Invalid 'Isolation:' '$isolation'. Must be one of: worktree, branch, inherit"
        errors=$((errors + 1))
        ;;
    esac
  fi

  if [ $errors -gt 0 ]; then
    return 1
  fi

  log_success "Micro-contract syntax and required keys validated successfully"
  return 0
}

# ------------------------------------------------------------------------------
# Task File & Parallel Wave Validation
# ------------------------------------------------------------------------------

# Parses tasks from a markdown file, validating micro-contracts and wave disjointness
validate_task_file() {
  local task_file="${1:-}"
  local check_waves_only="${2:-false}"

  if [ -z "$task_file" ] || [ ! -f "$task_file" ]; then
    log_error "Task file not found: $task_file"
    return 1
  fi

  log_info "Analyzing task definitions in: $task_file"

  local total_tasks=0
  local validated_contracts=0
  local errors=0

  # Data storage for waves: map wave_id -> list of "task_id:path"
  local wave_entries=()

  local current_task=""
  local current_wave=""
  local in_read=false
  local in_paths=false
  local current_read=()
  local current_paths=()
  local current_verify=""

  finalize_current_task() {
    if [ -n "$current_task" ]; then
      total_tasks=$((total_tasks + 1))

      # If task had micro-contract fields or was marked parallel/approved
      if [ ${#current_paths[@]} -gt 0 ] || [ -n "$current_verify" ] || [ -n "$current_wave" ]; then
        if [ "$check_waves_only" = "false" ]; then
          local task_errs=0
          if [ ${#current_read[@]} -eq 0 ]; then
            log_error "Task $current_task missing or empty 'Read:' key"
            task_errs=$((task_errs + 1))
          fi
          if [ ${#current_paths[@]} -eq 0 ]; then
            log_error "Task $current_task missing or empty 'Paths:' key"
            task_errs=$((task_errs + 1))
          fi
          if [ -z "$current_verify" ]; then
            log_error "Task $current_task missing or empty 'Verify:' key"
            task_errs=$((task_errs + 1))
          fi
          if [ $task_errs -eq 0 ]; then
            validated_contracts=$((validated_contracts + 1))
          else
            errors=$((errors + task_errs))
          fi
        fi

        # Register paths for wave disjointness verification
        if [ -n "$current_wave" ]; then
          for p in "${current_paths[@]}"; do
            wave_entries+=("${current_wave}|${current_task}|${p}")
          done
        fi
      fi
    fi

    current_task=""
    current_wave=""
    in_read=false
    in_paths=false
    current_read=()
    current_paths=()
    current_verify=""
  }

  while IFS= read -r line || [ -n "$line" ]; do
    # Skip markdown blockquotes, comments, or table rows
    if [[ "$line" =~ ^[[:space:]]*\> ]] || [[ "$line" =~ ^[[:space:]]*\| ]]; then
      continue
    fi

    # Check for new task declaration: e.g. [01.1] or Task [01.1]
    if [[ "$line" =~ \[[0-9]{2}\.[0-9]+(\.[0-9]+)?\] ]]; then
      local matched_task="${BASH_REMATCH[0]}"

      # Finalize preceding task if any
      finalize_current_task

      current_task="$matched_task"

      # Check for parallel wave tag e.g. [PARALLEL: W1]
      if [[ "$line" =~ \[PARALLEL:[[:space:]]*(W[0-9]+)\] ]]; then
        current_wave="${BASH_REMATCH[1]}"
      fi
      continue
    fi

    # Inside a task block
    if [ -n "$current_task" ]; then
      # Check wave tag on secondary lines
      if [ -z "$current_wave" ] && [[ "$line" =~ \[PARALLEL:[[:space:]]*(W[0-9]+)\] ]]; then
        current_wave="${BASH_REMATCH[1]}"
      fi

      # Check key Read:
      if [[ "$line" =~ ^[[:space:]]*(-[[:space:]]*)?Read: ]]; then
        in_read=true
        in_paths=false
        local inline="${line#*Read:}"
        inline="$(normalize_path "$inline")"
        if [ -n "$inline" ] && [ "$inline" != "-" ]; then
          IFS=',' read -ra items <<< "$inline"
          for it in "${items[@]}"; do
            it="$(normalize_path "$it")"
            [ -n "$it" ] && current_read+=("$it")
          done
        fi
        continue
      fi

      # Check key Paths:
      if [[ "$line" =~ ^[[:space:]]*(-[[:space:]]*)?Paths: ]]; then
        in_read=false
        in_paths=true
        local inline="${line#*Paths:}"
        inline="$(normalize_path "$inline")"
        if [ -n "$inline" ] && [ "$inline" != "-" ]; then
          IFS=',' read -ra items <<< "$inline"
          for it in "${items[@]}"; do
            it="$(normalize_path "$it")"
            [ -n "$it" ] && current_paths+=("$it")
          done
        fi
        continue
      fi

      # Check key Verify:
      if [[ "$line" =~ ^[[:space:]]*(-[[:space:]]*)?Verify: ]]; then
        in_read=false
        in_paths=false
        current_verify="${line#*Verify:}"
        current_verify="$(normalize_path "$current_verify")"
        continue
      fi

      # List items under Read:
      if [ "$in_read" = "true" ]; then
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+) ]]; then
          local item="${BASH_REMATCH[1]}"
          item="$(normalize_path "$item")"
          [ -n "$item" ] && current_read+=("$item")
          continue
        elif [[ "$line" =~ ^[[:space:]]*[A-Za-z]+: ]]; then
          in_read=false
        fi
      fi

      # List items under Paths:
      if [ "$in_paths" = "true" ]; then
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+) ]]; then
          local item="${BASH_REMATCH[1]}"
          item="$(normalize_path "$item")"
          [ -n "$item" ] && current_paths+=("$item")
          continue
        elif [[ "$line" =~ ^[[:space:]]*[A-Za-z]+: ]]; then
          in_paths=false
        fi
      fi

      # End of task block detection: horizontal rule or new heading
      if [[ "$line" =~ ^--- ]] || [[ "$line" =~ ^##[[:space:]] ]]; then
        finalize_current_task
      fi
    fi
  done < "$task_file"

  # Finalize trailing task
  finalize_current_task

  # Validate Wave Disjointness
  log_info "Verifying parallel wave mutual disjointness..."
  local wave_conflicts=0

  if [ ${#wave_entries[@]} -gt 0 ]; then
    local count=${#wave_entries[@]}
    for (( i=0; i<count; i++ )); do
      local entry_i="${wave_entries[$i]}"
      local wave_i task_i path_i
      IFS='|' read -r wave_i task_i path_i <<< "$entry_i"

      for (( j=i+1; j<count; j++ )); do
        local entry_j="${wave_entries[$j]}"
        local wave_j task_j path_j
        IFS='|' read -r wave_j task_j path_j <<< "$entry_j"

        # Check only if in the same wave but belonging to different tasks
        if [ "$wave_i" = "$wave_j" ] && [ "$task_i" != "$task_j" ]; then
          if paths_collide "$path_i" "$path_j"; then
            log_error "Parallel Wave Conflict in [$wave_i]:"
            echo "   Task $task_i path: '$path_i'" >&2
            echo "   collides with" >&2
            echo "   Task $task_j path: '$path_j'" >&2
            wave_conflicts=$((wave_conflicts + 1))
          fi
        fi
      done
    done
  fi

  if [ $wave_conflicts -gt 0 ]; then
    log_error "Found $wave_conflicts parallel wave path collision(s) in $task_file"
    errors=$((errors + wave_conflicts))
  else
    log_success "Parallel wave disjointness verified: zero overlapping mutable paths in identical waves"
  fi

  if [ "$check_waves_only" = "false" ]; then
    log_success "Task file validation completed ($validated_contracts micro-contract(s) audited)"
  fi

  if [ $errors -gt 0 ]; then
    return 1
  fi
  return 0
}

# ------------------------------------------------------------------------------
# Worktree Blast Boundary & Integration Gate
# ------------------------------------------------------------------------------

# Inspects a git worktree against a micro-contract
# Usage: verify_worktree <worktree_dir> <contract_file> [--base-ref <ref>] [--run-verify]
verify_worktree() {
  local worktree_dir="${1:-}"
  local contract_file="${2:-}"
  shift 2 || true

  local base_ref="HEAD"
  local run_verify=false

  while [ $# -gt 0 ]; do
    case "$1" in
      --base-ref)
        base_ref="$2"
        shift 2
        ;;
      --run-verify)
        run_verify=true
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 2
        ;;
    esac
  done

  if [ -z "$worktree_dir" ] || [ ! -d "$worktree_dir" ]; then
    log_error "Worktree directory does not exist or is not a directory: $worktree_dir"
    return 1
  fi
  if [ -z "$contract_file" ] || [ ! -f "$contract_file" ]; then
    log_error "Contract file does not exist: $contract_file"
    return 1
  fi

  log_info "Inspecting worktree blast boundaries: $worktree_dir"
  log_info "Contract specification: $contract_file"

  # Extract whitelisted Paths from contract
  local whitelist_paths=()
  local in_paths=false
  local verify_cmd=""

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^[[:space:]]*(-[[:space:]]*)?Paths: ]]; then
      in_paths=true
      local inline="${line#*Paths:}"
      inline="$(normalize_path "$inline")"
      if [ -n "$inline" ] && [ "$inline" != "-" ]; then
        IFS=',' read -ra items <<< "$inline"
        for it in "${items[@]}"; do
          it="$(normalize_path "$it")"
          [ -n "$it" ] && whitelist_paths+=("$it")
        done
      fi
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*(-[[:space:]]*)?Verify: ]]; then
      in_paths=false
      verify_cmd="${line#*Verify:}"
      verify_cmd="$(normalize_path "$verify_cmd")"
      continue
    fi

    if [ "$in_paths" = "true" ]; then
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.+) ]]; then
        local it="${BASH_REMATCH[1]}"
        it="$(normalize_path "$it")"
        [ -n "$it" ] && whitelist_paths+=("$it")
      elif [[ "$line" =~ ^[[:space:]]*[A-Za-z]+: ]]; then
        in_paths=false
      fi
    fi
  done < "$contract_file"

  if [ ${#whitelist_paths[@]} -eq 0 ]; then
    log_error "Contract $contract_file contains no 'Paths:' entries in whitelist"
    return 1
  fi

  log_info "Allowed whitelist (${#whitelist_paths[@]} paths): ${whitelist_paths[*]}"

  # Check modified/uncommitted/untracked files in the worktree
  local touched_files=()

  # 1. Staged and unstaged tracked changes relative to base_ref
  while IFS= read -r f; do
    [ -n "$f" ] && touched_files+=("$f")
  done < <(git -C "$worktree_dir" diff --name-only "$base_ref" 2>/dev/null || true)

  # 2. Untracked files
  while IFS= read -r f; do
    [ -n "$f" ] && touched_files+=("$f")
  done < <(git -C "$worktree_dir" ls-files --others --exclude-standard 2>/dev/null || true)

  # 3. Porcelain status for uncommitted modifications/renames/deletions
  while IFS= read -r status_line; do
    local f="${status_line:3}"
    f="$(normalize_path "$f")"
    [ -n "$f" ] && touched_files+=("$f")
  done < <(git -C "$worktree_dir" status --porcelain 2>/dev/null || true)

  # Deduplicate touched files
  local unique_touched=()
  if [ ${#touched_files[@]} -gt 0 ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && unique_touched+=("$line")
    done < <(printf '%s\n' "${touched_files[@]}" | sort -u)
  fi

  log_info "Detected ${#unique_touched[@]} touched file(s) in worktree"

  # Assert blast boundaries
  local violations=0
  for f in "${unique_touched[@]}"; do
    if ! path_matches_whitelist "$f" "${whitelist_paths[@]}"; then
      log_error "Blast Boundary Violation: File '$f' was modified but is outside whitelisted Paths:"
      violations=$((violations + 1))
    fi
  done

  if [ $violations -gt 0 ]; then
    log_error "Worktree verification failed with $violations blast radius violation(s)"
    return 1
  fi
  log_success "All touched files strictly adhere to delegated Paths: boundary"

  # Verify Git whitespace hygiene via git diff --check
  log_info "Checking Git whitespace hygiene (git diff --check)..."
  if ! git -C "$worktree_dir" diff --check "$base_ref" >/dev/null 2>&1; then
    log_error "Git whitespace check failed in worktree against $base_ref:"
    git -C "$worktree_dir" diff --check "$base_ref" >&2 || true
    return 1
  fi
  log_success "Git whitespace hygiene validated (zero trailing whitespace / merge markers)"

  # Run verification command if requested
  if [ "$run_verify" = "true" ]; then
    if [ -z "$verify_cmd" ]; then
      log_error "Contract specifies no 'Verify:' command to execute"
      return 1
    fi

    # Pre-execution security blast-radius audit
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local auditor="${script_dir}/audit-command-security.sh"
    if [ -x "$auditor" ]; then
      log_info "Auditing verification command security blast radius: $verify_cmd"
      if ! "$auditor" scan-command "$verify_cmd"; then
        log_error "Verification command rejected by security audit: $verify_cmd"
        return 1
      fi
      log_success "Verification command approved by security audit"
    fi

    log_info "Executing contract verification command: $verify_cmd"
    if ! ( cd "$worktree_dir" && eval "$verify_cmd" ); then
      log_error "Verification command failed with non-zero exit code: $verify_cmd"
      return 1
    fi
    log_success "Verification command passed successfully: $verify_cmd"
  fi

  log_success "Worktree $worktree_dir successfully passed all pre-integration guardrails"
  return 0
}

# ------------------------------------------------------------------------------
# Comprehensive Hermetic Self-Test Suite
# ------------------------------------------------------------------------------

run_self_tests() {
  log_info "Starting hermetic test suite for verify-microcontract.sh..."
  local test_tmp
  test_tmp="$(mktemp -d "${TMPDIR:-/tmp}/verify-microcontract-test.XXXXXX")"
  TMP_CLEANUP_DIRS+=("$test_tmp")

  local passed=0
  local failed=0

  run_test_case() {
    local name="$1"
    local expected_code="$2"
    shift 2

    log_info "Test: $name"
    local actual_code=0
    ( "$@" ) > "$test_tmp/stdout.log" 2> "$test_tmp/stderr.log" || actual_code=$?

    if [ "$actual_code" -eq "$expected_code" ]; then
      log_success "PASSED (exit code $actual_code)"
      passed=$((passed + 1))
    else
      log_error "FAILED (expected $expected_code, got $actual_code)"
      cat "$test_tmp/stderr.log" >&2
      failed=$((failed + 1))
    fi
  }

  # 1. Valid standalone contract
  cat << 'EOF' > "$test_tmp/valid_contract.md"
Role: Worker
Task: [04.1] Setup Foundation
Isolation: worktree
Read:
  - docs/spec.md
  - .agent/INVARIANTS.md
Paths:
  - src/foundation/index.ts
  - tests/foundation.test.ts
Verify: npm test
EOF
  run_test_case "Valid micro-contract passes" 0 \
    validate_single_contract "$test_tmp/valid_contract.md"

  # 2. Missing Read: key
  cat << 'EOF' > "$test_tmp/missing_read.md"
Role: Worker
Task: [04.1]
Paths:
  - src/index.ts
Verify: npm test
EOF
  run_test_case "Missing Read: key fails" 1 \
    validate_single_contract "$test_tmp/missing_read.md"

  # 3. Missing Paths: key
  cat << 'EOF' > "$test_tmp/missing_paths.md"
Role: Worker
Task: [04.1]
Read:
  - src/index.ts
Verify: npm test
EOF
  run_test_case "Missing Paths: key fails" 1 \
    validate_single_contract "$test_tmp/missing_paths.md"

  # 4. Missing Verify: key
  cat << 'EOF' > "$test_tmp/missing_verify.md"
Role: Worker
Task: [04.1]
Read:
  - src/index.ts
Paths:
  - src/index.ts
EOF
  run_test_case "Missing Verify: key fails" 1 \
    validate_single_contract "$test_tmp/missing_verify.md"

  # 5. Invalid Isolation: key
  cat << 'EOF' > "$test_tmp/invalid_isolation.md"
Role: Worker
Task: [04.1]
Isolation: invalid_mode
Read:
  - src/index.ts
Paths:
  - src/index.ts
Verify: npm test
EOF
  run_test_case "Invalid Isolation: value fails" 1 \
    validate_single_contract "$test_tmp/invalid_isolation.md"

  # 6. Parallel wave with disjoint paths passes
  cat << 'EOF' > "$test_tmp/tasks_disjoint.md"
## Active Task
- **Task:** [04.1] Module A [APPROVED] [PARALLEL: W1]
  - Read:
    - docs/spec.md
  - Paths:
    - src/module_a/code.ts
  - Verify: test -f src/module_a/code.ts

- **Task:** [04.2] Module B [APPROVED] [PARALLEL: W1]
  - Read:
    - docs/spec.md
  - Paths:
    - src/module_b/code.ts
  - Verify: test -f src/module_b/code.ts
EOF
  run_test_case "Parallel wave disjoint paths pass" 0 \
    validate_task_file "$test_tmp/tasks_disjoint.md"

  # 7. Parallel wave with colliding exact paths fails
  cat << 'EOF' > "$test_tmp/tasks_colliding.md"
## Active Task
- **Task:** [04.1] Module A [APPROVED] [PARALLEL: W1]
  - Read:
    - docs/spec.md
  - Paths:
    - src/shared/common.ts
  - Verify: npm test

- **Task:** [04.2] Module B [APPROVED] [PARALLEL: W1]
  - Read:
    - docs/spec.md
  - Paths:
    - src/shared/common.ts
  - Verify: npm test
EOF
  run_test_case "Parallel wave identical path collision fails" 1 \
    validate_task_file "$test_tmp/tasks_colliding.md"

  # 8. Parallel wave with prefix directory collision fails
  cat << 'EOF' > "$test_tmp/tasks_prefix_collision.md"
## Active Task
- **Task:** [04.1] Entire module directory [APPROVED] [PARALLEL: W2]
  - Read:
    - docs/spec.md
  - Paths:
    - src/core/
  - Verify: npm test

- **Task:** [04.2] Subfile inside directory [APPROVED] [PARALLEL: W2]
  - Read:
    - docs/spec.md
  - Paths:
    - src/core/subfile.ts
  - Verify: npm test
EOF
  run_test_case "Parallel wave directory prefix collision fails" 1 \
    validate_task_file "$test_tmp/tasks_prefix_collision.md"

  # 9. Worktree blast boundary: whitelisted modifications pass
  local repo_dir="$test_tmp/repo"
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init -q -b main
  git -C "$repo_dir" config user.name "Test Lead"
  git -C "$repo_dir" config user.email "lead@test.internal"
  echo "initial" > "$repo_dir/init.txt"
  mkdir -p "$repo_dir/src"
  echo "export const a = 1;" > "$repo_dir/src/a.ts"
  git -C "$repo_dir" add . && git -C "$repo_dir" commit -q -m "initial commit"

  local wt_dir="$test_tmp/worktree"
  git -C "$repo_dir" worktree add -q -b task-test "$wt_dir" HEAD

  cat << 'EOF' > "$test_tmp/wt_contract.md"
Role: Worker
Task: [04.1]
Isolation: worktree
Read:
  - init.txt
Paths:
  - src/a.ts
Verify: test -f src/a.ts
EOF

  echo "export const a = 2;" > "$wt_dir/src/a.ts"
  run_test_case "Worktree modifying whitelisted file passes" 0 \
    verify_worktree "$wt_dir" "$test_tmp/wt_contract.md" --base-ref HEAD

  # 10. Worktree blast boundary: unauthorized modification fails
  echo "unauthorized" > "$wt_dir/unauthorized.txt"
  run_test_case "Worktree modifying file outside Paths whitelist fails" 1 \
    verify_worktree "$wt_dir" "$test_tmp/wt_contract.md" --base-ref HEAD

  # 11. Worktree execution of Verify: command
  rm -f "$wt_dir/unauthorized.txt"
  run_test_case "Worktree execution of Verify: command passes" 0 \
    verify_worktree "$wt_dir" "$test_tmp/wt_contract.md" --base-ref HEAD --run-verify

  # 12. Worktree execution of failing Verify: command fails
  cat << 'EOF' > "$test_tmp/failing_verify_contract.md"
Role: Worker
Task: [04.1]
Isolation: worktree
Read:
  - init.txt
Paths:
  - src/a.ts
Verify: false
EOF
  run_test_case "Worktree execution with failing Verify: command fails" 1 \
    verify_worktree "$wt_dir" "$test_tmp/failing_verify_contract.md" --base-ref HEAD --run-verify

  # 13. Worktree execution with hazardous Verify: command is blocked by security audit
  cat << 'EOF' > "$test_tmp/hazardous_verify_contract.md"
Role: Worker
Task: [04.1]
Isolation: worktree
Read:
  - init.txt
Paths:
  - src/a.ts
Verify: sudo rm -rf /
EOF
  run_test_case "Worktree with hazardous Verify: command rejected by security audit" 1 \
    verify_worktree "$wt_dir" "$test_tmp/hazardous_verify_contract.md" --base-ref HEAD --run-verify

  # 14. Worktree git whitespace hygiene failure
  echo "export const a = 3;   " > "$wt_dir/src/a.ts"
  run_test_case "Worktree with trailing whitespace fails git diff --check" 1 \
    verify_worktree "$wt_dir" "$test_tmp/wt_contract.md" --base-ref HEAD

  # Cleanup worktree
  git -C "$repo_dir" worktree remove --force "$wt_dir" 2>/dev/null || true

  # 15. Audit actual project .agent/TASK.md if present
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local hub_root
  hub_root="$(cd "$script_dir/../.." && pwd)"

  if [ -f "$hub_root/.agent/TASK.md" ]; then
    run_test_case "Audit repository .agent/TASK.md" 0 \
      validate_task_file "$hub_root/.agent/TASK.md"
  fi

  echo "======================================================="
  echo -e "Self-Test Suite Results: ${GREEN}${passed} passed${RESET}, ${RED}${failed} failed${RESET}"
  echo "======================================================="

  if [ "$failed" -gt 0 ]; then
    return 1
  fi
  return 0
}

# ------------------------------------------------------------------------------
# Entrypoint Router
# ------------------------------------------------------------------------------

main() {
  local cmd="${1:-self-test}"

  case "$cmd" in
    self-test|test|all)
      run_self_tests
      ;;
    verify-file)
      shift
      validate_task_file "${1:-}"
      ;;
    verify-contract)
      shift
      validate_single_contract "${1:-}"
      ;;
    verify-waves)
      shift
      validate_task_file "${1:-}" true
      ;;
    verify-worktree)
      shift
      verify_worktree "$@"
      ;;
    -h|--help|help)
      show_help
      exit 0
      ;;
    -v|--version|version)
      echo "verify-microcontract.sh v${VERSION}"
      exit 0
      ;;
    *)
      # If first argument is an existing markdown file, treat as verify-file
      if [ -f "$cmd" ] && [[ "$cmd" == *.md ]]; then
        validate_task_file "$cmd"
      else
        log_error "Unknown command or option: $cmd"
        show_help
        exit 2
      fi
      ;;
  esac
}

main "$@"
