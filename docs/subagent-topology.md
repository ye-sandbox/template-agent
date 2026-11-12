---
author_type: agent-assisted
author: Architecture Team
reviewed_by: Human Lead
date: 2026-11-06
status: accepted
type: architectural-specification
---

# Subagent Role Taxonomy & Delegation Specification

Canonical specification for multi-agent collaboration, subagent delegation micro-contracts, workspace isolation, and fail-stop escalation within the Agent-Driven Development (ADD) Template Hub.

---

## 1. Overview & Core Philosophy

In Agent-Driven Development (ADD), multi-agent operations must prevent context degradation, race conditions on shared files, and unverified code churn. 

This specification establishes:
- A strict **3-Tier Subagent Topology** with distinct responsibilities and boundaries.
- A deterministic **Delegation Micro-Contract** (`Role:`, `Task:`, `Isolation:`, `Read:`, `Paths:`, `Verify:`).
- **Progressive Context Budgeting** to minimize token consumption and maximize instruction fidelity.
- **Fail-Stop Escalation** protocols for subagent execution.

---

## 2. 3-Tier Subagent Taxonomy

| Tier & Role | Core Responsibility | Primary Interfaces | Boundary & Invariants |
| :--- | :--- | :--- | :--- |
| **`Lead / Orchestrator`** | Interactive planning, task decomposition into parallel waves, task lifecycle in `.agent/TASK.md`, human interaction, and branch management. | `.agent/TASK.md`, `.agent/NOTES.md`, Chat Turn, `run-wave.sh` | Sole manager of `TASK.md` lifecycle. Does not execute file edits for parallel worker tasks directly. |
| **`Worker / Implementer`** | Autonomous task execution strictly within designated mutable filepaths. | Isolated worktree, delegated files, local bash runner | Bounded strictly by delegated `Paths:`. Must not modify files outside whitelist. Follows Definition of Done (DoD). |
| **`Reviewer / Sentinel`** | Independent verification of diffs, test suite execution, invariant checks, and DoD compliance. | Git diff, test harness (`Verify:` command), read-only tools | Read-only. Must not author code fixes. Emits structured Pass/Fail payload with falsifiable proof. |

---

## 3. Delegation Micro-Contract Standard

When the `Lead / Orchestrator` invokes or queues subagents (e.g. via `task-queue`, `run-wave.sh`, or background harnesses), each task MUST be bounded by a machine-parseable micro-contract:

```markdown
Role: Worker | Reviewer
Task: [XX.Y] <Canonical Task Title>
Isolation: branch | worktree | inherit
Read:
  - <path/to/context-file-1>
  - <path/to/context-file-2>
Paths:
  - <path/to/mutable-target-1>
  - <path/to/mutable-target-2>
Verify: <deterministic shell command, e.g. npm test or ./tests/smoke.sh>
```

### Field Definitions

- **`Role`**: The operational tier assigned (`Worker` or `Reviewer`).
- **`Task`**: The canonical `[XX.Y]` or `[XX.Y.Z]` task identifier from `.agent/TASK.md`.
- **`Isolation`**:
  - `worktree`: Dedicated isolated Git worktree branched from current HEAD (`git worktree add`).
  - `branch`: Dedicated branch checkout.
  - `inherit`: In-tree shared execution (strictly prohibited for parallel write operations on overlapping files).
- **`Read`**: Explicit, minimal file list loaded for progressive disclosure. Workers MUST NOT load full repo history. Procedural guidelines and skills must be self-contained within `.agent/skills/` or injected directly into the task dispatch prompt by the orchestrator.
- **`Paths`**: Strict whitelist of files or directories the worker is permitted to mutate. Edits outside this list are treated as DoD violations. All file mutations MUST be strictly contained within the project repository.
- **`Verify`**: Single command asserting that the change works and meets acceptance criteria.

---

## 4. Progressive Context Budgeting

Subagents suffer performance degradation when overloaded with irrelevant context. The orchestration layer enforces:

1. **Worker Context Budget (Minimalist):**
   - Base directives: Starter `AGENTS.md` (read-only rules and DoD).
   - Task micro-contract (`Read:` and `Paths:`).
   - Zero historical task logs: Workers do NOT read `.agent/ARCHIVE.md` or git log history beyond task scope.
2. **Reviewer Context Budget (Diff-Centric):**
   - Task acceptance criteria.
   - Output of `git diff` against base branch.
   - Output of `Verify:` execution.
3. **Lead Context Budget (State-Centric):**
   - `AGENTS.md`, active task in `.agent/TASK.md`, active contracts in `.agent/NOTES.md`.

---

## 5. Parallel Wave Execution & Workspace Isolation

For tasks marked `[PARALLEL: Wx]`:

1. **File Disjointness Invariant:**
   - Multiple workers executing in the same wave MUST have mutually disjoint `Paths:` sets. Overlapping mutable paths in the same wave are strictly prohibited.
2. **Worktree Isolation & Dependency Bootstrapping:**
   - Detailed specification and lifecycle recipes: [`docs/worktree-isolation.md`](worktree-isolation.md).
   - When executing parallel worker subagents, each worker operates in an isolated `git worktree`:
     ```bash
     git worktree add -b task-xx-y /tmp/worktrees/task-xx-y HEAD
     ```
   - **Dependency Bootstrapping (Fast-Link vs. Isolated-Install):**
     - If delegated `Paths:` does not alter dependency manifests (`package.json`, `pyproject.toml`, etc.), the runner uses **Fast-Link** (<50ms, zero-copy symlink of `node_modules/` or `.venv/` to root).
     - If delegated `Paths:` includes dependency manifests, the runner executes **Isolated-Install** inside the worktree using global caches.
     - Untracked `.env` configuration is safely copied from root to the worktree for test suite execution.
   - Upon successful verification (`Verify:` exits 0), the worker commits atomically and the lead fast-forwards or cherry-picks the commit.
   - Clean up worktrees promptly: `git worktree remove --force /tmp/worktrees/task-xx-y && git branch -D task-xx-y && git worktree prune`.
3. **Hermetic Sandboxing & Blast Radius Containment:**
   - Detailed specification and container/Bubblewrap profiles: [`docs/agent-sandbox.md`](agent-sandbox.md).
   - Worker subagents execute inside unprivileged sandboxes with read-only system binaries, ephemeral `tmpfs /tmp`, and air-gapped network namespaces to prevent host pollution and credential exfiltration.

### 5.1 Sequential Sub-Task Batching & Prompt Cache Hygiene (`[BATCH: Bx]`)

When a feature `[XX.YY]` decomposes into atomic sequential subtasks (`[XX.YY.01]` $\rightarrow$ `[XX.YY.02]` $\rightarrow$ `[XX.YY.03]`) that share types, schemas, or services within the same architectural layer, spawning a fresh worker or chat per subtask wastes prompt cache prefixes (90% read discount) and repeatedly pays repository discovery costs.

1. **Batch Grouping (`[BATCH: Bx]`):**
   - Group **2 to 4 sequential subtasks** belonging to the **same architectural layer** (`Type: code` for Backend/API/Domain, or `Type: browser-qa` / `mobile-qa` / `preview-mockup` for UI/Frontend).
   - Unlike `[PARALLEL: Wx]`, subtasks inside the same `[BATCH: Bx]` MAY have overlapping or dependent `Paths:` (e.g., `ZZ.01` creates the repository, `ZZ.02` consumes it in a service, `ZZ.03` exposes the route).
   - **Static Layer Boundary:** Mixing Backend/DB code with Frontend/UI or `browser-qa`/`mobile-qa` inside the same `[BATCH: Bx]` is strictly prohibited and rejected at lint time by `.github/scripts/verify-microcontract.sh verify-batches`.

2. **Ephemeral Feature Spec Anchor (`.agent/scratch/specs/XX-YY.md`):**
   - During `[XX.YY]` planning, author a concise (<150 lines) untracked feature specification at `.agent/scratch/specs/XX-YY.md` containing shared types/contracts, exact file paths by layer, and local business invariants.
   - Reference `.agent/scratch/specs/XX-YY.md` in the `Read:` list of each `[XX.YY.ZZ]` subtask.
   - `.github/scripts/bootstrap-worktree.sh` automatically copies `.agent/scratch/specs/` from the primary repository root into isolated worktrees so delegated workers immediately access the anchor without polluting `git log`.

3. **Continuous Warm-Cache Execution & Atomic Commits:**
   - **Interactive Mode (`proceed`):** The agent executes `ZZ.01` $\rightarrow$ runs `Verify:` $\rightarrow$ creates an atomic `git commit` $\rightarrow$ immediately proceeds to `ZZ.02` and `ZZ.03` in the same session, preserving 100% of the cached prompt prefix.
   - **Delegated Worker Mode (`delegate_task`):** The Lead Orchestrator dispatches the entire `[BATCH: Bx]` to a single Worker in one isolated worktree, instructing it to execute each `ZZ` sequentially with its own `Verify:` check and atomic commit.
   - **Zero Extra Error Counters:** Workers do NOT track separate "debug line/error counters" to decide whether to abort a batch mid-flight (avoiding goal displacement during debugging). Execution relies exclusively on the canonical Fail-Stop circuit breaker (Section 7).

---

## 6. Reviewer Quality Gate & Falsifiable Report

Before any task transition from `RUNNING` to completed:
1. Reviewer executes `Verify:` command.
2. Reviewer inspects `git diff --check` and ensures no broken relative links exist.
3. Reviewer produces a structured verification report:

```yaml
task_id: "[XX.Y]"
reviewer_verdict: "PASS | FAIL"
verification_command: "<exact command ran>"
verification_exit_code: 0
diff_stat: "+42 -10 across 2 files"
invariants_verified:
  - "No mutable paths violated"
  - "Zero broken relative links"
  - "Atomic conventional commit authored"
```

---

## 7. Fail-Stop Escalation & Circuit Breaker

If a worker or reviewer encounters consecutive failures matching the circuit breaker threshold (3 failures for general starters, 2 for sensitive environments like `blackbox`, `infra`, `baremetal`):
1. Subagent MUST halt immediately.
2. Subagent emits the standard escalation payload:
   ```yaml
   failure_stage: "<stage>"
   error_signature: "<exact error message>"
   consecutive_failures: <count>
   root_cause_analysis: "<technical hypothesis>"
   pending_decision: "<clarification requested from lead or human>"
   ```
3. Control returns to `Lead / Orchestrator` to request human intervention or revise planning.

---

## 8. Multi-Account Quota Routing & Failover Protocol

When orchestrating parallel waves (`[PARALLEL: Wx]`) and autonomous worker subagents across multiple Antigravity profiles, runners adhere to a deterministic quota preservation and failover protocol:

### 1. Profile Routing Priority
- **Secondary Account Priority:** Autonomous worker tasks MUST prioritize secondary accounts (`select-profile.sh --exclude-current` or `multigravity dispatch`), preserving the primary profile's quota for the Lead Orchestrator's interactive planning turns.
- **Interactive Fallback:** Runners fall back to the active/current IDE profile ONLY when no secondary profile possesses sufficient quota.

### 2. 5% Quota Floor & Circuit Breaker
- Any profile with `remaining_fraction <= 0.05` (5% remaining quota) is disqualified from dispatch and automated priming.
- If all candidate profiles are below the 5% quota floor or rate-limited (`429`), the runner halts and escalates to the Lead Orchestrator with the standard diagnostic payload.

### 3. Model Tier Selection & Escalation Hierarchy
- **Default Tier:** Autonomous workers default to `gemini-3.8-flash-medium` for low token consumption, zero unnecessary overhead, and high-throughput wave execution.
- **Escalation Tier:** Escalation to `gemini-4-argon-medium` is permitted ONLY for:
  1. Substantive architectural synthesis explicitly designated in planning.
  2. At most **1 retry** following a verification failure (`verify_failed`).
- **Hard Stop:** If verification fails a second time under the escalated model, the runner halts immediately.

### 4. Rate-Limit Persistence & Cooldowns
- 429 rate limit responses and quota state changes are persisted in `<profile>/.multigravity/quota-history.jsonl` to prevent immediate re-dispatch to rate-limited accounts.

### 5. Worktree Verification & Recovery
- If a worker process lingers or reaches timeout after authoring code, the harness executes the task's `Verify:` command inside the isolated worktree.
- If `Verify:` exits with code 0 and staged files adhere to `Paths:`, the harness recovers the worktree diff, creates an atomic commit, and cleans up the worktree without loss of work.
