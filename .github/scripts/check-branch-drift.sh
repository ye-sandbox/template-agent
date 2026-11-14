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
    elif [ "$(git rev-parse "$MAIN_REF:$file")" != "$(git rev-parse "$ref:$file")" ]; then
      fail "Drift detected in '$file' between main and branch '$branch' ($ref)."
    fi
  done
done

# 2b. Audit Shared Canonical Lifecycle Hooks and Interface Skill (Byte-for-byte Parity)
CANONICAL_PROTOCOL_FILES=(
  ".agent/hooks/README.md"
  ".agent/skills/interface-testing/SKILL.md"
)

echo "🔍 Verifying byte-for-byte parity of shared canonical lifecycle hooks and interface skill..."
for file in "${CANONICAL_PROTOCOL_FILES[@]}"; do
  main_content="$(git show "$MAIN_REF:$file" 2>/dev/null || true)"
  if [ -z "$main_content" ]; then
    fail "Canonical protocol file '$file' missing on main branch ($MAIN_REF)."
    continue
  fi

  for branch in "${STARTER_BRANCHES[@]}"; do
    ref="$(resolve_ref "$branch")"
    branch_content="$(git show "$ref:$file" 2>/dev/null || true)"
    if [ -z "$branch_content" ]; then
      fail "Branch '$branch' ($ref) is missing canonical protocol file '$file'."
    elif [ "$(git rev-parse "$MAIN_REF:$file")" != "$(git rev-parse "$ref:$file")" ]; then
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
  ".worktrees/"
  ".maestri/"
  ".multigravity/"
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

# 4. Audit Presence and LLM Gateway Hygiene of .env.example Across All Branches
echo "🔍 Verifying presence and LLM gateway hygiene of .env.example across all branches..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  env_content="$(git show "$ref:.env.example" 2>/dev/null || true)"
  if [ -z "$env_content" ]; then
    fail "Branch '$branch' ($ref) is missing .env.example."
    continue
  fi

  for req_var in "LLM_BASE_URL" "LLM_API_KEY" "LLM_MODEL_FAST" "LLM_MODEL_DEEP" "LLM_TIMEOUT_SECONDS"; do
    if ! echo "$env_content" | grep -qE "^[[:space:]]*${req_var}="; then
      fail "Branch '$branch' ($ref) .env.example missing required variable: '$req_var'."
    fi
  done
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

# 6. Audit Multi-Agent Micro-Contract & Parallel Wave Invariants in .agent/TASK.md
echo "🔍 Verifying multi-agent micro-contract and wave invariants in .agent/TASK.md across all branches..."
for branch in "${STARTER_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  task_content="$(git show "$ref:.agent/TASK.md" 2>/dev/null || true)"
  if [ -z "$task_content" ]; then
    fail "Branch '$branch' ($ref) is missing .agent/TASK.md."
    continue
  fi

  if ! echo "$task_content" | grep -qE '\[PARALLEL: W[0-9]+\]'; then
    fail "Branch '$branch' ($ref) .agent/TASK.md missing standardized parallel wave tag pattern '[PARALLEL: Wx]'."
  fi

  if ! echo "$task_content" | grep -qE '\[BATCH: B[0-9]+\]'; then
    fail "Branch '$branch' ($ref) .agent/TASK.md missing standardized sequential batch tag pattern '[BATCH: Bx]'."
  fi

  if ! echo "$task_content" | grep -qF '.agent/scratch/specs/'; then
    fail "Branch '$branch' ($ref) .agent/TASK.md missing '.agent/scratch/specs/' feature anchor guidance."
  fi

  if ! echo "$task_content" | grep -qF 'Read:'; then
    fail "Branch '$branch' ($ref) .agent/TASK.md missing micro-contract 'Read:' field."
  fi

  if ! echo "$task_content" | grep -qF 'Paths:'; then
    fail "Branch '$branch' ($ref) .agent/TASK.md missing micro-contract 'Paths:' field."
  fi

  if ! echo "$task_content" | grep -qF 'Verify:'; then
    fail "Branch '$branch' ($ref) .agent/TASK.md missing micro-contract 'Verify:' field."
  fi

  if ! echo "$task_content" | grep -qF '[APPROVED]'; then
    fail "Branch '$branch' ($ref) .agent/TASK.md missing '[APPROVED]' pre-approval tag guidance."
  fi
done

# 7. Audit Multi-Agent & Quota Routing Contracts in .agent/NOTES.md Across All Branches
echo "🔍 Verifying multi-agent topology and quota routing contracts in .agent/NOTES.md across all branches..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  notes_content="$(git show "$ref:.agent/NOTES.md" 2>/dev/null || true)"
  if [ -z "$notes_content" ]; then
    fail "Branch '$branch' ($ref) is missing .agent/NOTES.md."
    continue
  fi

  if ! echo "$notes_content" | grep -q 'Multi-Account Quota Routing & Failover Contract'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'Multi-Account Quota Routing & Failover Contract' table."
  fi

  if ! echo "$notes_content" | grep -q 'Worktree Isolation & Dependency Bootstrap Contract'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'Worktree Isolation & Dependency Bootstrap Contract' table."
  fi

  if ! echo "$notes_content" | grep -qF '.agent/scratch/specs/'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing '.agent/scratch/specs/' propagation contract."
  fi

  if ! echo "$notes_content" | grep -q 'Lead / Orchestrator'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing canonical 'Lead / Orchestrator' role."
  fi

  if ! echo "$notes_content" | grep -q 'Worker / Implementer'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing canonical 'Worker / Implementer' role."
  fi

  if ! echo "$notes_content" | grep -q 'Reviewer / Sentinel'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing canonical 'Reviewer / Sentinel' role."
  fi
done

# 8. Audit Hermetic Agent Sandbox & Container Isolation Contracts in .agent/NOTES.md Across All Branches
echo "🔍 Verifying hermetic sandbox and container isolation contracts in .agent/NOTES.md across all branches..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  notes_content="$(git show "$ref:.agent/NOTES.md" 2>/dev/null || true)"
  if [ -z "$notes_content" ]; then
    fail "Branch '$branch' ($ref) is missing .agent/NOTES.md."
    continue
  fi

  if ! echo "$notes_content" | grep -q 'Hermetic Agent Sandbox & Container Isolation Contract'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'Hermetic Agent Sandbox & Container Isolation Contract' table."
  fi

  if ! echo "$notes_content" | grep -q 'Tier 1 (Bubblewrap)'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'Tier 1 (Bubblewrap)' entry."
  fi

  if ! echo "$notes_content" | grep -q 'Tier 2 (Rootless Container)'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'Tier 2 (Rootless Container)' entry."
  fi

  if ! echo "$notes_content" | grep -q 'audit-command-security.sh'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'audit-command-security.sh' fallback entry."
  fi
done

# 9. Audit LLM Gateway & Virtual Model Routing Contracts in .agent/NOTES.md Across All Branches
echo "🔍 Verifying LLM gateway and virtual model routing contracts in .agent/NOTES.md across all branches..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  notes_content="$(git show "$ref:.agent/NOTES.md" 2>/dev/null || true)"
  if [ -z "$notes_content" ]; then
    fail "Branch '$branch' ($ref) is missing .agent/NOTES.md."
    continue
  fi

  if ! echo "$notes_content" | grep -q 'LLM Gateway & Virtual Model Routing Contract'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'LLM Gateway & Virtual Model Routing Contract' table."
  fi

  routing_row="$(printf '%s\n' "$notes_content" | grep -F '| **Virtual Model Routing** |' || true)"
  env_content="$(git show "$ref:.env.example" 2>/dev/null || true)"
  for variable in LLM_MODEL_FAST LLM_MODEL_DEEP; do
    # Parse literal aliases only; never source configuration as shell code.
    alias_value="$(printf '%s\n' "$env_content" | sed -nE "s/^[[:space:]]*${variable}[[:space:]]*=[[:space:]]*(.*)/\\1/p")"
    alias_value="$(printf '%s\n' "$alias_value" | sed -E "s/[[:space:]]+#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//; s/^[\"']//; s/[\"']$//")"
    if [[ ! "$alias_value" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]]; then
      fail "Branch '$branch' ($ref) .env.example requires one literal $variable alias."
    elif ! printf '%s\n' "$routing_row" | grep -Fq "\`$alias_value\`"; then
      fail "Branch '$branch' ($ref) .agent/NOTES.md missing declared $variable alias '$alias_value'."
    fi
  done

  if ! echo "$notes_content" | grep -q 'hydra_shared_net'; then
    fail "Branch '$branch' ($ref) .agent/NOTES.md missing 'hydra_shared_net' network boundary entry."
  fi
done

# 10. Compare only the shared interface section; retain branch-specific fences.
interface_section() {
  awk '
    /^## 7[.] Adaptive Interface Verification & UI Protocol$/ { active = 1 }
    active && (/^---$/ || (/^## / && $0 !~ /^## 7[.] /)) { exit }
    active { print }
  '
}

canonical_invariants="$(git show "$MAIN_REF:.agent/INVARIANTS.md" 2>/dev/null || true)"
canonical_interface="$(printf '%s\n' "$canonical_invariants" | interface_section)"
if [ -z "$canonical_interface" ]; then
  fail "Canonical Invariant 7 missing on main ($MAIN_REF)."
fi
for invariant in 7.1 7.2 7.3 7.4; do
  if ! printf '%s\n' "$canonical_interface" | grep -Fq "Invariant $invariant"; then
    fail "Canonical Invariant $invariant missing on main ($MAIN_REF)."
  fi
done

echo "🔍 Verifying adaptive interface invariants, context triggers, and DoD..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  invariants="$(git show "$ref:.agent/INVARIANTS.md" 2>/dev/null || true)"
  section="$(printf '%s\n' "$invariants" | interface_section)"
  heading_count="$(printf '%s\n' "$invariants" | grep -c '^## 7[.] Adaptive Interface Verification & UI Protocol$' || true)"
  if [ -z "$section" ] || [ "$heading_count" -ne 1 ] || [ "$section" != "$canonical_interface" ]; then
    fail "Branch '$branch' ($ref) Invariant 7 missing, duplicated, or drifted from main."
  fi
  agents="$(git show "$ref:AGENTS.md" 2>/dev/null || true)"
  context="$(printf '%s\n' "$agents" | sed -n '/^## .*Modular Context Triggers/,/^## /p')"
  dod="$(printf '%s\n' "$agents" | sed -n '/^### Step 3: Falsifiable Definition of Done/,/^## /p')"
  if ! printf '%s\n' "$context" | grep -Fq '.agent/skills/interface-testing/SKILL.md'; then
    fail "Branch '$branch' ($ref) AGENTS.md missing on-demand interface skill trigger."
  fi
  if ! printf '%s\n' "$dod" | grep -Eq '^-[[:space:]]+\[ \].*Interface.*UI.*[Vv]erification'; then
    fail "Branch '$branch' ($ref) AGENTS.md missing interface verification DoD."
  fi
  for runtime in 'T3 Code' 'headless'; do
    if ! printf '%s\n' "$dod" | grep -Fq "$runtime"; then
      fail "Branch '$branch' ($ref) interface DoD missing '$runtime' verification path."
    fi
  done
done

# 11. Audit Sequential Batching ([BATCH: Bx]) and Hermetic Skills & Context Contract
hermetic_skills_section() {
  awk '
    /^## Hermetic Skills & Context Contract$/ { active = 1 }
    active && /^## / && $0 !~ /^## Hermetic Skills & Context Contract$/ { exit }
    active { print }
  '
}

canonical_skills_readme="$(git show "$MAIN_REF:.agent/skills/README.md" 2>/dev/null || true)"
canonical_hermetic_section="$(printf '%s\n' "$canonical_skills_readme" | hermetic_skills_section)"
if [ -z "$canonical_hermetic_section" ]; then
  fail "Canonical '## Hermetic Skills & Context Contract' missing in main .agent/skills/README.md ($MAIN_REF)."
fi

echo "🔍 Verifying sequential batching and hermetic skills contracts across all branches..."
for branch in "${ALL_BRANCHES[@]}"; do
  ref="$(resolve_ref "$branch")"
  agents="$(git show "$ref:AGENTS.md" 2>/dev/null || true)"
  if ! printf '%s\n' "$agents" | grep -Fq '[BATCH: Bx]'; then
    fail "Branch '$branch' ($ref) AGENTS.md missing sequential batching '[BATCH: Bx]' contract."
  fi
  if ! printf '%s\n' "$agents" | grep -Fq '.agent/scratch/specs/'; then
    fail "Branch '$branch' ($ref) AGENTS.md missing '.agent/scratch/specs/' feature anchor trigger."
  fi
  if ! printf '%s\n' "$agents" | grep -Fq 'Hermetic Skills & Context Contract'; then
    fail "Branch '$branch' ($ref) AGENTS.md missing 'Hermetic Skills & Context Contract' directive."
  fi

  if git cat-file -e "$ref:.agent/skills/README.md" 2>/dev/null; then
    skills_readme="$(git show "$ref:.agent/skills/README.md" 2>/dev/null || true)"
    section="$(printf '%s\n' "$skills_readme" | hermetic_skills_section)"
    if [ -z "$section" ] || [ "$section" != "$canonical_hermetic_section" ]; then
      fail "Branch '$branch' ($ref) .agent/skills/README.md Hermetic Skills section missing or drifted from main."
    fi
  fi
done

echo "======================================================="
if [ $ERRORS -gt 0 ]; then
  echo "❌ Drift audit failed with $ERRORS error(s)." >&2
  exit 1
else
  echo "✅ Inter-branch governance audit passed with 0 drift detected."
  exit 0
fi
