#!/usr/bin/env bash
# Exercise drift failures against disposable local refs; never mutate source refs.
set -euo pipefail
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/branch-drift-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

git init --quiet "$TEST_ROOT/repo"
# CI may have a detached HEAD and only origin/main; fetch both source layouts.
for branch in main greenfield brownfield blackbox infra baremetal; do
  source_ref=""
  for candidate in "refs/heads/$branch" "refs/remotes/origin/$branch"; do
    if git -C "$SOURCE_ROOT" rev-parse --verify "$candidate" >/dev/null 2>&1; then
      source_ref="$candidate"
      break
    fi
  done
  if [ -z "$source_ref" ]; then
    echo "Missing source branch: $branch" >&2
    exit 1
  fi
  git -C "$TEST_ROOT/repo" fetch --quiet --no-tags "$SOURCE_ROOT" "$source_ref:refs/remotes/origin/$branch"
done
mkdir -p "$TEST_ROOT/repo/.github/scripts"
cp "$SOURCE_ROOT/.github/scripts/check-branch-drift.sh" "$TEST_ROOT/repo/.github/scripts/check-branch-drift.sh"
cd "$TEST_ROOT/repo"
export GIT_AUTHOR_NAME="Contract Test" GIT_COMMITTER_NAME="Contract Test"
export GIT_AUTHOR_EMAIL="test@example.invalid" GIT_COMMITTER_EMAIL="test@example.invalid"
export GIT_INDEX_FILE="$TEST_ROOT/index"
PASSED=0

expect() {
  local expected="$1" signature="$2" actual=0
  bash .github/scripts/check-branch-drift.sh > "$TEST_ROOT/output" 2>&1 || actual=$?
  if [ "$actual" -ne "$expected" ] || ! grep -Fq "$signature" "$TEST_ROOT/output"; then
    cat "$TEST_ROOT/output" >&2
    echo "FAIL: expected exit $expected and diagnostic '$signature'; got $actual" >&2
    exit 1
  fi
  PASSED=$((PASSED + 1))
  echo "PASS: $signature"
}

prepare() {
  git read-tree origin/greenfield
  git show "origin/greenfield:$1" > "$TEST_ROOT/content"
}

publish() {
  local path="$1" blob tree commit
  blob="$(git hash-object -w "$TEST_ROOT/content")"
  git update-index --add --cacheinfo 100644 "$blob" "$path"
  tree="$(git write-tree)"
  commit="$(printf '%s\n' 'test: mutate disposable contract' | git commit-tree "$tree" -p origin/greenfield)"
  git update-ref refs/heads/greenfield "$commit"
}

expect 0 '0 drift detected'

skill='.agent/skills/interface-testing/SKILL.md'
prepare "$skill"
git update-index --force-remove "$skill"
tree="$(git write-tree)"
commit="$(printf '%s\n' 'test: omit skill' | git commit-tree "$tree" -p origin/greenfield)"
git update-ref refs/heads/greenfield "$commit"
expect 1 "missing canonical protocol file '$skill'"

prepare "$skill"
printf '\n' >> "$TEST_ROOT/content"
publish "$skill"
expect 1 "Drift detected in '$skill'"

invariants='.agent/INVARIANTS.md'
prepare "$invariants"
sed 's/Invariant 7.4/Removed guardrail/' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish "$invariants"
expect 1 'Invariant 7 missing, duplicated, or drifted'

prepare "$invariants"
printf '\n## 7. Adaptive Interface Verification & UI Protocol\n' >> "$TEST_ROOT/content"
publish "$invariants"
expect 1 'Invariant 7 missing, duplicated, or drifted'

prepare AGENTS.md
sed '/^- \*\*Interface & UI Verification:/d' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish AGENTS.md
expect 1 'missing on-demand interface skill trigger'

prepare AGENTS.md
sed '/^- \[ \] Interface & UI Verification/d' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish AGENTS.md
expect 1 'missing interface verification DoD'

prepare .env.example
sed 's/^LLM_MODEL_FAST=.*/LLM_MODEL_FAST=missing-alias/' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish .env.example
expect 1 "missing declared LLM_MODEL_FAST alias 'missing-alias'"

# An alias substring is not a documented alias token.
prepare .env.example
baseline_fast="$(git show origin/greenfield:.env.example | sed -n 's/^LLM_MODEL_FAST=//p')"
substring="${baseline_fast:1}"
sed "s|^LLM_MODEL_FAST=.*|LLM_MODEL_FAST=$substring|" "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish .env.example
expect 1 "missing declared LLM_MODEL_FAST alias '$substring'"

prepare .env.example
printf '\nLLM_MODEL_FAST=duplicate-alias\n' >> "$TEST_ROOT/content"
publish .env.example
expect 1 'requires one literal LLM_MODEL_FAST alias'

prepare .env.example
sed -E "s/^(LLM_MODEL_FAST|LLM_MODEL_DEEP)=(.*)/\1='\2' # literal default/" "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish .env.example
expect 0 '0 drift detected'

# Local branches take priority over origin refs, without prescribing alias names.
prepare .env.example
sed 's/^LLM_MODEL_FAST=.*/LLM_MODEL_FAST=fixture-fast/' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
blob="$(git hash-object -w "$TEST_ROOT/content")"
git update-index --add --cacheinfo 100644 "$blob" .env.example
git show origin/greenfield:.agent/NOTES.md | sed -E 's/(\| \*\*Virtual Model Routing\*\* \| `)[^`]+/\1fixture-fast/' > "$TEST_ROOT/content"
publish .agent/NOTES.md
expect 0 '0 drift detected'

skills_readme='.agent/skills/README.md'
prepare "$skills_readme"
sed '/^## Hermetic Skills & Context Contract$/,$d' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish "$skills_readme"
expect 1 'Hermetic Skills section missing or drifted'

prepare AGENTS.md
sed '/\[BATCH: Bx\]/d' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish AGENTS.md
expect 1 "AGENTS.md missing sequential batching '[BATCH: Bx]' contract"

prepare .agent/NOTES.md
sed 's|\.agent/scratch/specs/||g' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish .agent/NOTES.md
expect 1 "NOTES.md missing '.agent/scratch/specs/' propagation contract"

prepare .agent/TASK.md
sed 's/\[BATCH: B1\]/[SEQ]/g' "$TEST_ROOT/content" > "$TEST_ROOT/next"
mv "$TEST_ROOT/next" "$TEST_ROOT/content"
publish .agent/TASK.md
expect 1 "TASK.md missing standardized sequential batch tag pattern '[BATCH: Bx]'"

echo "Branch drift regression tests: $PASSED passed"
