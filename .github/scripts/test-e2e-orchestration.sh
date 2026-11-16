#!/usr/bin/env bash
# ==============================================================================
# End-to-End Orchestration Lifecycle Test (hermetic)
# Builds a temp repo with a TASK.md containing a 2-subtask [BATCH: B1-backend]
# and a 2-task [PARALLEL: W1], provisions worktrees via bootstrap-worktree.sh,
# runs verify-microcontract.sh verify-worktree, and asserts atomic commits,
# integration, and worktree teardown. No network, no host credentials.
#
# Usage: test-e2e-orchestration.sh
# Exit codes: 0 all assertions passed; 1 assertion failure.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
VERIFY="${SCRIPT_DIR}/verify-microcontract.sh"
BOOTSTRAP="${SCRIPT_DIR}/bootstrap-worktree.sh"

export NO_COLOR=1
# Hermetic git identity/config: ignore host global/system config.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME="E2E Agent" GIT_AUTHOR_EMAIL="e2e@test.internal"
export GIT_COMMITTER_NAME="E2E Agent" GIT_COMMITTER_EMAIL="e2e@test.internal"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/e2e-orch.XXXXXX")"
TMP="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT INT TERM

PASS=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { PASS=$((PASS + 1)); echo "ok - $*"; }
expect_rc() { # expect_rc <rc> <desc> <cmd...>
  local want="$1" desc="$2" rc=0
  shift 2
  "$@" >"$TMP/out.log" 2>&1 || rc=$?
  if [ "$rc" -ne "$want" ]; then
    cat "$TMP/out.log" >&2
    fail "$desc (expected rc=$want, got rc=$rc)"
  fi
  ok "$desc"
}

REPO="$TMP/repo"
WT="$TMP/worktrees"
mkdir -p "$REPO/.agent" "$REPO/src" "$WT"
cd "$REPO"
git init -q -b main

cat > .agent/TASK.md << 'EOF'
## Active Task

- **Task:** `[90.1.1]` `[APPROVED]` `[BATCH: B1-backend]` Add alpha module
  - Type: code
  - Read:
    - README.md
  - Paths:
    - src/alpha.txt
  - Verify: test -f src/alpha.txt

- **Task:** `[90.1.2]` `[APPROVED]` `[BATCH: B1-backend]` Add beta module
  - Type: code
  - Read:
    - README.md
  - Paths:
    - src/beta.txt
  - Verify: test -f src/beta.txt

- **Task:** `[90.2]` `[APPROVED]` `[PARALLEL: W1]` Add gamma module
  - Type: code
  - Read:
    - README.md
  - Paths:
    - src/gamma.txt
  - Verify: test -f src/gamma.txt

- **Task:** `[90.3]` `[APPROVED]` `[PARALLEL: W1]` Add delta module
  - Type: code
  - Read:
    - README.md
  - Paths:
    - src/delta.txt
  - Verify: test -f src/delta.txt
EOF
echo "# e2e repo" > README.md
touch src/.gitkeep
printf '.worktrees/\n.agent/scratch/\n.agent/.cache/\n.env\n' > .gitignore
echo "KEY=value" > .env.example
git add -A && git commit -q -m "chore: initial commit"
BASE="$(git rev-parse HEAD)"

# --- Contract-level validation of the composed TASK.md ------------------------
expect_rc 0 "verify-file accepts 2-subtask batch + 2-task wave" "$VERIFY" verify-file .agent/TASK.md
expect_rc 0 "verify-batches accepts B1-backend" "$VERIFY" verify-batches .agent/TASK.md
expect_rc 0 "verify-waves accepts disjoint W1" "$VERIFY" verify-waves .agent/TASK.md

# Per-task contract snippets (what an orchestrator hands to a worker).
mkcontract() { # mkcontract <name> <path> <verify>
  cat > "$TMP/$1.md" << EOF
- **Task:** \`[$1]\`
  - Read:
    - README.md
  - Paths:
    - $2
  - Verify: $3
EOF
}
mkcontract alpha src/alpha.txt "test -f src/alpha.txt"
mkcontract beta  src/beta.txt  "test -f src/beta.txt"
mkcontract gamma src/gamma.txt "test -f src/gamma.txt"
mkcontract delta src/delta.txt "test -f src/delta.txt"
for c in alpha beta gamma delta; do
  expect_rc 0 "verify-contract accepts $c" "$VERIFY" verify-contract "$TMP/$c.md"
done

provision() { # provision <branch> <path>
  git worktree add -q -b "$1" "$2" HEAD
  "$BOOTSTRAP" --root "$REPO" --worktree "$2" >/dev/null
}
teardown() { # teardown <branch> <path>
  git worktree remove --force "$2"
  git branch -D "$1" >/dev/null
  git worktree prune
}

# --- Sequential batch: one warm worktree, atomic commit per subtask -----------
provision task-batch-b1 "$WT/batch-b1"
[ -d "$WT/batch-b1/.agent/scratch" ] || fail "bootstrap did not provision .agent/scratch"
[ -f "$WT/batch-b1/.env" ] || fail "bootstrap did not propagate .env.example"
ok "batch worktree provisioned via bootstrap-worktree.sh"

echo "alpha" > "$WT/batch-b1/src/alpha.txt"
expect_rc 0 "batch subtask 1 passes verify-worktree --run-verify" \
  "$VERIFY" verify-worktree "$WT/batch-b1" "$TMP/alpha.md" --run-verify
git -C "$WT/batch-b1" add src/alpha.txt
git -C "$WT/batch-b1" commit -q -m "feat(e2e): add alpha module"
B1_C1="$(git -C "$WT/batch-b1" rev-parse HEAD)"

echo "beta" > "$WT/batch-b1/src/beta.txt"
echo "stray" > "$WT/batch-b1/src/stray.txt"
expect_rc 1 "batch subtask 2 rejects out-of-whitelist file" \
  "$VERIFY" verify-worktree "$WT/batch-b1" "$TMP/beta.md" --base-ref "$B1_C1"
rm "$WT/batch-b1/src/stray.txt"
expect_rc 0 "batch subtask 2 passes verify-worktree --run-verify" \
  "$VERIFY" verify-worktree "$WT/batch-b1" "$TMP/beta.md" --base-ref "$B1_C1" --run-verify
git -C "$WT/batch-b1" add src/beta.txt
git -C "$WT/batch-b1" commit -q -m "feat(e2e): add beta module"

[ "$(git -C "$WT/batch-b1" rev-list --count "$BASE..HEAD")" = "2" ] || fail "batch must produce exactly 2 commits"
[ "$(git -C "$WT/batch-b1" show --name-only --format= HEAD~1)" = "src/alpha.txt" ] || fail "batch commit 1 not atomic"
[ "$(git -C "$WT/batch-b1" show --name-only --format= HEAD)" = "src/beta.txt" ] || fail "batch commit 2 not atomic"
ok "batch produced 2 atomic commits (one file each)"

# --- Parallel wave: isolated worktree per task --------------------------------
provision task-90-2 "$WT/w1-gamma"
provision task-90-3 "$WT/w1-delta"
echo "gamma" > "$WT/w1-gamma/src/gamma.txt"
echo "delta" > "$WT/w1-delta/src/delta.txt"
expect_rc 0 "wave task gamma passes verify-worktree --run-verify" \
  "$VERIFY" verify-worktree "$WT/w1-gamma" "$TMP/gamma.md" --run-verify
expect_rc 0 "wave task delta passes verify-worktree --run-verify" \
  "$VERIFY" verify-worktree "$WT/w1-delta" "$TMP/delta.md" --run-verify
expect_rc 1 "wave task gamma rejected under delta's contract" \
  "$VERIFY" verify-worktree "$WT/w1-gamma" "$TMP/delta.md"
git -C "$WT/w1-gamma" add src/gamma.txt && git -C "$WT/w1-gamma" commit -q -m "feat(e2e): add gamma module"
git -C "$WT/w1-delta" add src/delta.txt && git -C "$WT/w1-delta" commit -q -m "feat(e2e): add delta module"

# --- Integration on main by cherry-pick (never merge) -------------------------
git -C "$REPO" cherry-pick "$B1_C1" "$(git -C "$WT/batch-b1" rev-parse HEAD)" \
  "$(git -C "$WT/w1-gamma" rev-parse HEAD)" "$(git -C "$WT/w1-delta" rev-parse HEAD)" >/dev/null
[ "$(git -C "$REPO" rev-list --count "$BASE..HEAD")" = "4" ] || fail "integration must yield 4 atomic commits"
for f in alpha beta gamma delta; do
  [ -f "$REPO/src/$f.txt" ] || fail "integrated tree missing src/$f.txt"
done
[ -z "$(git -C "$REPO" status --porcelain)" ] || fail "main working tree dirty after integration"
git -C "$REPO" diff --check "$BASE" >/dev/null || fail "git diff --check failed after integration"
ok "4 commits cherry-picked onto main; tree clean; diff --check passes"

# --- Teardown ------------------------------------------------------------------
teardown task-batch-b1 "$WT/batch-b1"
teardown task-90-2 "$WT/w1-gamma"
teardown task-90-3 "$WT/w1-delta"
[ "$(git -C "$REPO" worktree list | wc -l | tr -d ' ')" = "1" ] || fail "dangling worktrees remain"
for d in batch-b1 w1-gamma w1-delta; do
  [ ! -e "$WT/$d" ] || fail "worktree directory $d not removed"
done
[ -z "$(git -C "$REPO" branch --list 'task-*')" ] || fail "task branches not deleted"
ok "worktrees and task branches torn down"

echo "All $PASS e2e orchestration assertions passed."
