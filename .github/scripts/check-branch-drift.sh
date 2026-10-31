#!/usr/bin/env bash
# ==============================================================================
# Inter-Branch Governance & Drift Detection Script
# Audits synchronization, shared contracts, and CLI standards across branches
# ==============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

STARTER_BRANCHES=("greenfield" "brownfield" "blackbox" "infra" "baremetal")
ALL_BRANCHES=("main" "${STARTER_BRANCHES[@]}")

resolve_ref() {
  local branch="$1"
  if git rev-parse --verify "refs/heads/$branch" >/dev/null 2>&1; then
    echo "refs/heads/$branch"
  elif git rev-parse --verify "refs/remotes/origin/$branch" >/dev/null 2>&1; then
    echo "refs/remotes/origin/$branch"
  elif git rev-parse --verify "$branch" >/dev/null 2>&1; then
    echo "$branch"
  else
    echo ""
  fi
}

ERRORS=0

fail() {
  echo "❌ $1" >&2
  ERRORS=$((ERRORS + 1))
}

echo "======================================================="
echo "🔍 Inter-Branch Governance & Drift Audit"
echo "======================================================="

# 1. Verify existence of all target branches
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  if [ -z "$ref" ]; then
    fail "Branch '$branch' could not be resolved in local or remote refs."
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo "❌ Aborting audit due to unresolved branches." >&2
  exit 1
fi

MAIN_REF="$(resolve_ref "main")"

# 2. Audit Shared Canonical Knowledge Base Cards (Byte-for-byte Parity)
CANONICAL_KNOWLEDGE_FILES=(
  ".agent/knowledge/000-schema.md"
  ".agent/knowledge/k-000-template.md"
)

echo "🔍 Verifying byte-for-byte parity of shared canonical knowledge base cards..."
for file in "${CANONICAL_KNOWLEDGE_FILES[@]}"; do
  main_content="$(git show "$MAIN_REF:$file" 2>/dev/null || true)"
  if [ -z "$main_content" ]; then
    fail "Canonical file '$file' missing on main branch ($MAIN_REF)."
    continue
  fi

  for branch in "${STARTER_BRANCHES[@]}"; do
    ref="$(resolve_ref "$branch")"
    branch_content="$(git show "$ref:$file" 2>/dev/null || true)"
    if [ -z "$branch_content" ]; then
      fail "Branch '$branch' ($ref) is missing canonical file '$file'."
    elif [ "$main_content" != "$branch_content" ]; then
      fail "Drift detected in '$file' between main and branch '$branch' ($ref)."
    fi
  done
done

# 3. Audit Mandatory Invariants in .gitignore Across All Branches
MANDATORY_GITIGNORE_RULES=(
  ".env"
  "!.env.example"
  ".agent/scratch/"
  ".agent/.cache/"
  ".maestri/"
  "*.tsbuildinfo"
)

echo "🔍 Verifying mandatory .gitignore invariants across all branches..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  gitignore_content="$(git show "$ref:.gitignore" 2>/dev/null || true)"
  if [ -z "$gitignore_content" ]; then
    fail "Branch '$branch' ($ref) is missing .gitignore."
    continue
  fi

  for rule in "${MANDATORY_GITIGNORE_RULES[@]}"; do
    if ! echo "$gitignore_content" | grep -Fqx "$rule"; then
      fail "Branch '$branch' ($ref) .gitignore is missing mandatory invariant rule: '$rule'."
    fi
  done
done

# 4. Audit Presence of .env.example Across All Branches
echo "🔍 Verifying presence of .env.example across all branches..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  if ! git show "$ref:.env.example" >/dev/null 2>&1; then
    fail "Branch '$branch' ($ref) is missing .env.example."
  fi
done

# 5. Audit CLI Installer Standardization
echo "🔍 Verifying CLI flags and usage standardization across installers..."

# 5a. Starters with init.sh
INIT_BRANCHES=("greenfield" "blackbox" "infra" "baremetal")
for branch in "${INIT_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  init_content="$(git show "$ref:init.sh" 2>/dev/null || true)"
  if [ -z "$init_content" ]; then
    fail "Branch '$branch' ($ref) is missing init.sh."
    continue
  fi

  # Syntax check
  if ! bash -n <(echo "$init_content") >/dev/null 2>&1; then
    fail "Syntax error in init.sh on branch '$branch' ($ref)."
  fi

  # Usage line standardization
  if ! echo "$init_content" | grep -q 'Usage: init\.sh.*\[-y|--yes|-f|--force\]'; then
    fail "Branch '$branch' ($ref) init.sh usage string is not standardized to [-y|--yes|-f|--force]."
  fi

  # Argument parsing support
  if ! echo "$init_content" | grep -q '\-y|--yes|-f|--force)'; then
    fail "Branch '$branch' ($ref) init.sh does not parse -y|--yes|-f|--force."
  fi

  if ! echo "$init_content" | grep -q '\-h|--help)'; then
    fail "Branch '$branch' ($ref) init.sh does not parse -h|--help."
  fi

  # Portable temporary directory idioms
  if echo "$init_content" | grep -qE 'mktemp[[:space:]]+-d[[:space:]]*$'; then
    fail "Branch '$branch' ($ref) init.sh uses non-portable 'mktemp -d' without explicit template."
  fi

  # Onboarding flow & prompt standardization
  if ! echo "$init_content" | grep -q '👉 Next steps:'; then
    fail "Branch '$branch' ($ref) init.sh missing standardized '👉 Next steps:' header."
  fi

  if ! echo "$init_content" | grep -q 'Read AGENTS\.md, \.agent/TASK\.md'; then
    fail "Branch '$branch' ($ref) init.sh does not instruct agent to read AGENTS.md and .agent/TASK.md."
  fi

  if ! echo "$init_content" | grep -q 'Present your implementation plan for Task \[00\.1\]'; then
    fail "Branch '$branch' ($ref) init.sh does not instruct agent to present plan for Task [00.1]."
  fi
done

# 5b. Brownfield install.sh
BROWNFIELD_REF="$(resolve_ref "brownfield")"
install_content="$(git show "$BROWNFIELD_REF:install.sh" 2>/dev/null || true)"
if [ -z "$install_content" ]; then
  fail "Branch 'brownfield' ($BROWNFIELD_REF) is missing install.sh."
else
  if ! bash -n <(echo "$install_content") >/dev/null 2>&1; then
    fail "Syntax error in install.sh on branch 'brownfield' ($BROWNFIELD_REF)."
  fi

  if ! echo "$install_content" | grep -q 'Usage: install\.sh.*\[-y|--yes|-f|--force\]'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh usage string is not standardized to [-y|--yes|-f|--force]."
  fi

  if ! echo "$install_content" | grep -q '\[-l|--local-only|--stealth\]'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh usage string does not document stealth mode."
  fi

  if ! echo "$install_content" | grep -q '\-y|--yes|-f|--force)'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh does not parse -y|--yes|-f|--force."
  fi

  if ! echo "$install_content" | grep -q '\-l|--local-only|--stealth)'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh does not parse -l|--local-only|--stealth."
  fi

  if ! echo "$install_content" | grep -q '\-h|--help)'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh does not parse -h|--help."
  fi

  # Portable temporary file idioms
  if echo "$install_content" | grep -qE 'mktemp[[:space:]]*$'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh uses non-portable 'mktemp' without explicit template."
  fi

  # Onboarding flow & prompt standardization
  if ! echo "$install_content" | grep -q '👉 Next steps:'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh missing standardized '👉 Next steps:' header."
  fi

  if ! echo "$install_content" | grep -q 'Read AGENTS\.md, \.agent/TASK\.md, and \.agent/NOTES\.md\.'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh does not instruct agent to read AGENTS.md, .agent/TASK.md, and .agent/NOTES.md."
  fi

  if ! echo "$install_content" | grep -q 'Present your implementation plan for Task \[00\.1\] Project Discovery and Context Mapping'; then
    fail "Branch 'brownfield' ($BROWNFIELD_REF) install.sh does not instruct agent to present plan for Task [00.1]."
  fi
fi

echo "======================================================="
if [ $ERRORS -gt 0 ]; then
  echo "❌ Drift audit failed with $ERRORS error(s)." >&2
  exit 1
else
  echo "✅ Inter-branch governance audit passed with 0 drift detected."
  exit 0
fi
