#!/usr/bin/env bash
# ==============================================================================
# End-to-End Orchestration Lifecycle Test (characterization baseline)
#
# Hermetic test of the batch/wave lifecycle driven by the existing CLIs:
#   verify-microcontract.sh (verify-file / verify-worktree) and
#   bootstrap-worktree.sh (fast-link mode).
#
# Asserts observable behavior only (exit codes and output markers), so it can
# serve as the regression baseline for a future parser port.
#
# Hermeticity: temp repo (mktemp, removed by trap), no network, isolated HOME and
# git config, nothing written outside the temp directory. POSIX-ERE / macOS safe.
#
# Usage: test-e2e-orchestration.sh [-h|--help]
# Exit codes: 0 all assertions passed; 1 assertion failure; 2 usage error.
# ==============================================================================
set -euo pipefail

case "${1:-}" in
  -h|--help)
    sed -n '2,16p' "$0" | sed -E 's/^# ?//'
    exit 0
    ;;
  "") ;;
  *)
    echo "Unknown argument: $1" >&2
    exit 2
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
VERIFY="${SCRIPT_DIR}/verify-microcontract.sh"
BOOTSTRAP="${SCRIPT_DIR}/bootstrap-worktree.sh"

for s in "$VERIFY" "$BOOTSTRAP"; do
  [ -f "$s" ] || { echo "Missing dependency script: $s" >&2; exit 1; }
done

# Deterministic, colorless output so markers can be matched literally.
export NO_COLOR=1

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/e2e-orchestration.XXXXXX")"
TMP_ROOT="$(cd "$TMP_ROOT" && pwd -P)"
cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT INT TERM

# Isolate from host git config and dotfiles.
export HOME="${TMP_ROOT}/home"
mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="${TMP_ROOT}/gitconfig-empty"
: > "$GIT_CONFIG_GLOBAL"
export GIT_TERMINAL_PROMPT=0

REPO="${TMP_ROOT}/repo"
WT_DIR="${TMP_ROOT}/worktrees"
OUT_DIR="${TMP_ROOT}/out"
mkdir -p "$REPO" "$WT_DIR" "$OUT_DIR"

PASSED=0
FAILED=0

pass() { PASSED=$((PASSED + 1)); echo "  ok   - $1"; }
fail() { FAILED=$((FAILED + 1)); echo "  FAIL - $1" >&2; }

LAST_OUT=""
LAST_RC=0

# run <cmd...>: capture combined output and exit code without tripping set -e.
run() {
  LAST_RC=0
  LAST_OUT="$("$@" 2>&1)" || LAST_RC=$?
}

assert_rc() { # <expected> <label>
  if [ "$LAST_RC" -eq "$1" ]; then
    pass "$2 (exit $LAST_RC)"
  else
    fail "$2 (expected exit $1, got $LAST_RC)"
    echo "$LAST_OUT" | sed -E 's/^/       | /' >&2
  fi
}

assert_out() { # <fixed marker> <label>
  if printf '%s\n' "$LAST_OUT" | grep -qF -- "$1"; then
    pass "$2 [marker: $1]"
  else
    fail "$2 (missing marker: $1)"
    echo "$LAST_OUT" | sed -E 's/^/       | /' >&2
  fi
}

assert_true() { # <label> <cmd...>
  local label="$1"
  shift
  if "$@"; then pass "$label"; else fail "$label"; fi
}

assert_eq() { # <expected> <actual> <label>
  if [ "$1" = "$2" ]; then
    pass "$3"
  else
    fail "$3 (expected '$1', got '$2')"
  fi
}

g() { git -C "$REPO" "$@"; }

# ------------------------------------------------------------------------------
# Fixture: temp repo with TASK.md (2-subtask batch + 2-task wave)
# ------------------------------------------------------------------------------
echo "==> Building fixture repo"
git init -q "$REPO"
g symbolic-ref HEAD refs/heads/main
g config user.name "E2E Agent"
g config user.email "e2e@test.internal"
g config commit.gpgsign false

mkdir -p "${REPO}/.agent" "${REPO}/src/repos" "${REPO}/src/services" "${REPO}/docs" "${REPO}/node_modules/dummy"
echo "module.exports = {};" > "${REPO}/node_modules/dummy/index.js"
echo '{"name":"e2e-fixture"}' > "${REPO}/package.json"
echo "E2E_FLAG=1" > "${REPO}/.env.example"
printf '%s\n' ".env" "node_modules" ".agent/scratch/" ".agent/.cache/" > "${REPO}/.gitignore"
echo "seed" > "${REPO}/docs/a.md"
echo "seed" > "${REPO}/docs/b.md"
echo "export const seed = 1;" > "${REPO}/src/repos/deal.repo.ts"

cat > "${REPO}/.agent/TASK.md" << 'EOF'
# TASK.md

## Active Task

- [ ] **[91.1.1]** `[APPROVED]` `[BATCH: B1]` Create deal repository
  - `Type:` `code`
  - `Read:` `docs/a.md`
  - `Paths:` `src/repos/deal.repo.ts`
  - `Verify:` `test -f src/repos/deal.repo.ts`

- [ ] **[91.1.2]** `[APPROVED]` `[BATCH: B1]` Create deal service
  - `Type:` `code`
  - `Read:` `docs/a.md`
  - `Paths:` `src/repos/deal.repo.ts, src/services/deal.service.ts`
  - `Verify:` `test -f src/services/deal.service.ts`

- [ ] **[91.2]** `[APPROVED]` `[PARALLEL: W1]` Update doc A
  - `Type:` `code`
  - `Read:` `docs/a.md`
  - `Paths:` `docs/a.md`
  - `Verify:` `test -f docs/a.md`

- [ ] **[91.3]** `[APPROVED]` `[PARALLEL: W1]` Update doc B
  - `Type:` `code`
  - `Read:` `docs/b.md`
  - `Paths:` `docs/b.md`
  - `Verify:` `test -f docs/b.md`
EOF

g add -A
g commit -q -m "chore: seed e2e fixture"
BASE_SHA="$(g rev-parse HEAD)"
TASK_FILE="${REPO}/.agent/TASK.md"

# Per-task micro-contracts consumed by verify-worktree.
mkcontract() { # <file> <task> <verify> <paths...>
  local file="$1" task="$2" verify="$3"
  shift 3
  {
    echo "Role: Worker"
    echo "Task: [${task}]"
    echo "Isolation: worktree"
    echo "Read:"
    echo "  - docs/a.md"
    echo "Paths:"
    local p
    for p in "$@"; do echo "  - ${p}"; done
    echo "Verify: ${verify}"
  } > "$file"
}

C_B1="${OUT_DIR}/c-b1.md"
C_B2="${OUT_DIR}/c-b2.md"
C_W_A="${OUT_DIR}/c-wa.md"
C_W_B="${OUT_DIR}/c-wb.md"
mkcontract "$C_B1" "91.1.1" "test -f src/repos/deal.repo.ts" "src/repos/deal.repo.ts"
mkcontract "$C_B2" "91.1.2" "test -f src/services/deal.service.ts" "src/repos/deal.repo.ts" "src/services/deal.service.ts"
mkcontract "$C_W_A" "91.2" "test -f docs/a.md" "docs/a.md"
mkcontract "$C_W_B" "91.3" "test -f docs/b.md" "docs/b.md"

# ------------------------------------------------------------------------------
# 1. verify-file on the valid task file
# ------------------------------------------------------------------------------
echo "==> [1] verify-file on valid TASK.md"
run "$VERIFY" verify-file "$TASK_FILE"
assert_rc 0 "verify-file accepts batch + wave task file"
assert_out "Parallel wave disjointness verified" "wave disjointness reported"
assert_out "Sequential batches verified" "batch constraints reported"
assert_out "4 micro-contract(s) audited" "all four micro-contracts audited"

run "$VERIFY" verify-waves "$TASK_FILE"
assert_rc 0 "verify-waves accepts wave"
run "$VERIFY" verify-batches "$TASK_FILE"
assert_rc 0 "verify-batches accepts batch"

# ------------------------------------------------------------------------------
# 2. Provision worktrees (fast-link) via bootstrap-worktree.sh
# ------------------------------------------------------------------------------
echo "==> [2] Provision worktrees"
WT_B1="${WT_DIR}/task-b1"
WT_WA="${WT_DIR}/task-91-2"
WT_WB="${WT_DIR}/task-91-3"
WT_NEG="${WT_DIR}/task-neg"

provision() { # <branch> <path>
  g worktree add -q -b "$1" "$2" HEAD
  run "$BOOTSTRAP" --root "$REPO" --worktree "$2"
}

provision task-b1 "$WT_B1"
assert_rc 0 "bootstrap batch worktree"
assert_out "Fast-linked node_modules/" "fast-link mode used"
assert_true "node_modules is a symlink in batch worktree" test -L "${WT_B1}/node_modules"
assert_true ".env is an isolated copy (not a symlink)" bash -c "[ -f '${WT_B1}/.env' ] && [ ! -L '${WT_B1}/.env' ]"
assert_true "scratch directory provisioned" test -d "${WT_B1}/.agent/scratch"

provision task-91-2 "$WT_WA"
assert_rc 0 "bootstrap wave worktree A"
provision task-91-3 "$WT_WB"
assert_rc 0 "bootstrap wave worktree B"
provision task-neg "$WT_NEG"
assert_rc 0 "bootstrap negative-case worktree"

wt_git() { # <worktree> <git args...>
  local wt="$1"
  shift
  git -C "$wt" "$@"
}

for wt in "$WT_B1" "$WT_WA" "$WT_WB" "$WT_NEG"; do
  wt_git "$wt" config user.name "E2E Agent"
  wt_git "$wt" config user.email "e2e@test.internal"
  wt_git "$wt" config commit.gpgsign false
done

# ------------------------------------------------------------------------------
# 3. Batch lifecycle: two atomic commits in one worktree, verify after each
# ------------------------------------------------------------------------------
echo "==> [3] Batch B1 lifecycle (2 subtasks, 2 atomic commits)"
echo "export const repo = 1;" > "${WT_B1}/src/repos/deal.repo.ts"
wt_git "$WT_B1" add src/repos/deal.repo.ts
wt_git "$WT_B1" commit -q -m "feat(repo): add deal repository"
run "$VERIFY" verify-worktree "$WT_B1" "$C_B1" --base-ref "$BASE_SHA" --run-verify
assert_rc 0 "verify-worktree passes after subtask 91.1.1"
assert_out "All touched files strictly adhere to delegated Paths: boundary" "blast boundary respected (91.1.1)"
assert_out "Verification command passed successfully" "Verify: command executed (91.1.1)"

mkdir -p "${WT_B1}/src/services"
echo "export const service = 1;" > "${WT_B1}/src/services/deal.service.ts"
wt_git "$WT_B1" add src/services/deal.service.ts
wt_git "$WT_B1" commit -q -m "feat(service): add deal service"
run "$VERIFY" verify-worktree "$WT_B1" "$C_B2" --base-ref "$BASE_SHA" --run-verify
assert_rc 0 "verify-worktree passes after subtask 91.1.2"
assert_out "successfully passed all pre-integration guardrails" "integration guardrails passed (91.1.2)"

assert_eq "2" "$(wt_git "$WT_B1" rev-list --count "${BASE_SHA}..HEAD" | tr -d '[:space:]')" "batch produced exactly 2 commits"
assert_eq "src/repos/deal.repo.ts" "$(wt_git "$WT_B1" show --name-only --format= HEAD~1 | tr -d '[:space:]')" "commit 1 is atomic (single file)"
assert_eq "src/services/deal.service.ts" "$(wt_git "$WT_B1" show --name-only --format= HEAD | tr -d '[:space:]')" "commit 2 is atomic (single file)"
assert_eq "" "$(wt_git "$WT_B1" status --porcelain)" "batch worktree clean after commits"

# ------------------------------------------------------------------------------
# 4. Wave lifecycle: two disjoint tasks in separate worktrees
# ------------------------------------------------------------------------------
echo "==> [4] Wave W1 lifecycle (2 parallel tasks)"
echo "edited by task 91.2" >> "${WT_WA}/docs/a.md"
wt_git "$WT_WA" add docs/a.md
wt_git "$WT_WA" commit -q -m "docs(a): update doc a"
run "$VERIFY" verify-worktree "$WT_WA" "$C_W_A" --base-ref "$BASE_SHA" --run-verify
assert_rc 0 "verify-worktree passes for wave task 91.2"

echo "edited by task 91.3" >> "${WT_WB}/docs/b.md"
wt_git "$WT_WB" add docs/b.md
wt_git "$WT_WB" commit -q -m "docs(b): update doc b"
run "$VERIFY" verify-worktree "$WT_WB" "$C_W_B" --base-ref "$BASE_SHA" --run-verify
assert_rc 0 "verify-worktree passes for wave task 91.3"

assert_eq "1" "$(wt_git "$WT_WA" rev-list --count "${BASE_SHA}..HEAD" | tr -d '[:space:]')" "wave task A produced exactly 1 commit"
assert_eq "1" "$(wt_git "$WT_WB" rev-list --count "${BASE_SHA}..HEAD" | tr -d '[:space:]')" "wave task B produced exactly 1 commit"

# ------------------------------------------------------------------------------
# 5. Negative cases
# ------------------------------------------------------------------------------
echo "==> [5] Negative cases"

# 5a. Wave with overlapping Paths
OVERLAP_FILE="${OUT_DIR}/overlap.md"
cat > "$OVERLAP_FILE" << 'EOF'
## Active Task

- [ ] **[92.1]** `[APPROVED]` `[PARALLEL: W1]` Task one
  - `Type:` `code`
  - `Read:` `docs/a.md`
  - `Paths:` `docs/shared.md`
  - `Verify:` `test -f docs/a.md`

- [ ] **[92.2]** `[APPROVED]` `[PARALLEL: W1]` Task two
  - `Type:` `code`
  - `Read:` `docs/a.md`
  - `Paths:` `docs/shared.md`
  - `Verify:` `test -f docs/a.md`
EOF
run "$VERIFY" verify-file "$OVERLAP_FILE"
assert_rc 1 "wave with overlapping Paths is rejected"
assert_out "Parallel Wave Conflict" "wave conflict reported"

# 5b. Batch mixing backend and UI layers
MIXED_FILE="${OUT_DIR}/mixed.md"
cat > "$MIXED_FILE" << 'EOF'
## Active Task

- [ ] **[93.1.1]** `[APPROVED]` `[BATCH: B1]` Backend repository
  - `Type:` `code`
  - `Read:` `docs/a.md`
  - `Paths:` `src/repos/deal.repo.ts`
  - `Verify:` `test -f docs/a.md`

- [ ] **[93.1.2]** `[APPROVED]` `[BATCH: B1]` Frontend page
  - `Type:` `browser-qa`
  - `Read:` `docs/a.md`
  - `Paths:` `src/pages/Deals.tsx`
  - `Verify:` `test -f docs/a.md`
EOF
run "$VERIFY" verify-file "$MIXED_FILE"
assert_rc 1 "batch mixing backend and UI layers is rejected"
assert_out "Sequential Batch Layer Violation" "layer violation reported"

# 5c. Write outside Paths: fails verify-worktree (committed out-of-scope file)
echo "export const rogue = 1;" > "${WT_NEG}/src/rogue.ts"
wt_git "$WT_NEG" add src/rogue.ts
wt_git "$WT_NEG" commit -q -m "feat(rogue): add out-of-scope file"
run "$VERIFY" verify-worktree "$WT_NEG" "$C_W_A" --base-ref "$BASE_SHA"
assert_rc 1 "write outside Paths: is rejected by verify-worktree"
assert_out "Blast Boundary Violation" "blast boundary violation reported"

# ------------------------------------------------------------------------------
# 6. Teardown: no dangling worktrees or branches
# ------------------------------------------------------------------------------
echo "==> [6] Teardown"
for pair in "task-b1:${WT_B1}" "task-91-2:${WT_WA}" "task-91-3:${WT_WB}" "task-neg:${WT_NEG}"; do
  branch="${pair%%:*}"
  path="${pair#*:}"
  g worktree remove --force "$path"
  g branch -q -D "$branch"
done
g worktree prune

assert_eq "1" "$(g worktree list --porcelain | grep -c '^worktree ')" "only the primary worktree remains registered"
assert_eq "" "$(g branch --list 'task-*' | tr -d '[:space:]')" "no task-* branches remain"
assert_true "worktree directories removed from disk" bash -c "[ ! -e '${WT_B1}' ] && [ ! -e '${WT_WA}' ] && [ ! -e '${WT_WB}' ] && [ ! -e '${WT_NEG}' ]"
assert_eq "main" "$(g rev-parse --abbrev-ref HEAD)" "primary repo still on main"
assert_eq "$BASE_SHA" "$(g rev-parse HEAD)" "primary repo HEAD untouched"

# ------------------------------------------------------------------------------
echo "======================================================="
echo "E2E orchestration test: ${PASSED} passed, ${FAILED} failed"
echo "======================================================="
[ "$FAILED" -eq 0 ]
