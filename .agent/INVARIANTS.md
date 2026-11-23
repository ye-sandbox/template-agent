# INVARIANTS.md — System Invariants and Untouchable Rules

> 🧱 **Chesterton's Fence Principle:**
> *"Never remove a rule, filter, or unusual piece of code until you understand why it was put there."*
>
> This file is the canonical source of truth for **system invariants, runtime guardrails, and untouchable rules** that govern agent execution across `template-agent` repositories.

---

## How to Use this File (for the Agent)

1. **Check before any architectural modification:** Always consult this file before altering test harnesses, runtime boundaries, interfaces, or branch structures.
2. **Document implicit rules upon discovery:** When investigating bugs or discovering non-obvious constraints, document them here immediately with technical rationale.
3. **Do not confuse with `NOTES.md`:** `NOTES.md` tracks live collaboration contracts and topology. `INVARIANTS.md` tracks **strict constraints and inviolable system rules**.

---

## 1. Branch Isolation & Repository Invariants

- **Zero Cross-Branch Merges:** Starters exist as disjoint roots on specialized branches (`main`, `greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`). Merging across template branches is strictly forbidden (`[P0]`). Propagation is performed exclusively via atomic cherry-picking or selective file checkout (`git checkout <branch> -- <path>`).
- **Clean Starter Roots:** Template starter files must never be placed directly on `main`. `main` is exclusively the governance and documentation hub.

---

## 2. ADR Consolidation & Documentation Invariants

- **Single ADR Diary:** All architectural decisions must append to `docs/adr/decisions.md`. Prohibit creating individual ADR files or separate `.agent/adr/` directories (`[P1]`).
- **Heading Ban in `NOTES.md`:** `NOTES.md` must never contain task-specific headings (`## [Task XX.Y]`). Task history lives in `git log` and `.agent/ARCHIVE.md`.

---

## 3. Multi-Agent & Worktree Isolation Invariants

- **Disjoint Micro-Contracts (`[PARALLEL: Wx]`):** Subagents operating in parallel waves (`[PARALLEL: Wx]`) must operate on mutually disjoint mutable paths (`Paths:`).
- **Sequential Sub-Task Batching (`[BATCH: Bx]`):** Sequential atomic subtasks (`ZZ`) within the same feature (`XX.YY`) may be grouped into batches of **2 to 4 subtasks** ONLY when they belong to the same architectural layer (`Type:`). Mixing Backend (`Type: code`) with Frontend/UI (`Type: browser-qa` / `mobile-qa` / `preview-mockup`) in a single batch is prohibited. Shared feature contracts live in untracked `.agent/scratch/specs/XX-YY.md` and are copied into isolated worktrees by `bootstrap-worktree.sh`.
- **Fast-Link vs. Isolated-Install:** Worktree provisioning must use Fast-Link (symlink `node_modules/` or `.venv/`) when manifest files are unaltered, and Isolated-Install when dependencies change.
- **Hermetic Lifecycle Cleanup:** Git worktrees and scratch directories (`.agent/scratch/`) must be cleanly deprovisioned post-integration without dangling locks.

---

## 4. LLM Gateway & Model Routing Invariants

- **Standard OpenAI v1 Gateway:** Consumer applications must connect through OpenAI v1 compatible gateway abstractions (`/v1/chat/completions`) using virtual aliases (`fast`, `deep`), eliminating proprietary provider lock-in.
- **Client Timeout & Reasoning Headroom:** Deep reasoning virtual models require client HTTP timeouts $\ge 180\text{s}$. Automated test probes must allocate `max_tokens >= 60` to prevent reasoning tokens from exhausting the response budget.
- **Docker Network Isolation:** Consumer containers must attach to `hydra_shared_net` and are strictly forbidden from joining internal router networks (`hydra_ai_net`).

---

## 5. Security & Blast Radius Invariants

- **Destructive Command Ban:** `git push --force`, `git reset --hard`, and `git clean -fd` are prohibited without explicit human authorization.
- **Static Pre-Execution Audit:** Autonomous runners executing arbitrary shell commands must pass static blast-radius auditing (`audit-command-security.sh`).
- **Credential Hygiene:** Credentials, private tokens, and real `.env` contents must never be staged, committed, or transmitted across worktree boundaries.

---

## 6. Telemetry & Log Suppression Invariants

- **Healthcheck Probe Suppression:** High-frequency HTTP 200 healthcheck pings (`/health`, `/healthz`) must be filtered from production access logs and ingestion pipelines to prevent log store flooding.

---

## 7. Adaptive Interface Verification & UI Protocol

- **Invariant 7.1 (Runtime-Aware Interface Verification):**
  - **Inside T3 Code:** When undertaking frontend, preview, or UI component tasks in a T3 Code environment, agents must verify visual and interactive behaviors using preview and device MCP tools (`preview_status`, `preview_open`, `preview_snapshot`, `preview_act`, `device_open`). Agents must check `preview_status` before opening tabs and prefer accessibility/snapshot locators over coordinates.
  - **Outside T3 Code (Headless CLI / CI):** In headless terminal runtimes or CI pipelines, agents must verify interfaces through non-blocking build, component, and E2E test suites (`npm run build`, `vitest`, `playwright --headless`), without hanging on graphical display servers.
- **Invariant 7.2 (Prohibition of Blind Preview Launches):**
  - Agents must NEVER invoke `preview_open` or launch mobile emulators to retrieve static web documentation or perform general search queries. Static web research belongs exclusively to headless HTTP tools (`read_url_content`, web search).
- **Invariant 7.3 (Mandatory Preview Lifecycle Cleanup):**
  - Any preview browser tab or device emulator session opened by an agent during execution MUST be explicitly closed (`preview_close`, `device_close`) before handing back control to the human or completing the task.
- **Invariant 7.4 (Non-Blocking Server Containment):**
  - Local development or preview servers started for interface testing must be run as manageable background tasks on ephemeral ports, and terminated immediately once verification concludes.
