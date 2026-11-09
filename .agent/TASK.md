# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[06.4]` Starter Template Parity: Propagate Interface Verification & Invariants
- **Status:** PLANNING
- **Scope:** Propagate interface verification contracts, runtime-aware Invariant 7 guardrails, and on-demand skill to specialized template branches (`greenfield`, `brownfield`, etc.) ensuring zero drift and starter parity.
- **Target Branches:** `greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`
- **Role:** Worker
- **Isolation:** worktree
- **Approved Plan:**
  1. Inspect each target branch in an isolated worktree before reading its starter contracts; preserve branch-specific scope, failure thresholds, and clean task templates.
  2. Update only each starter's `AGENTS.md` interface context trigger and verification DoD, propagate the canonical Invariant 7 section while preserving existing invariants, and selectively check out `.agent/skills/interface-testing/SKILL.md` from `main`.
  3. Verify skill parity, invariant coverage, relative links and branch targets, allowed-path boundaries, and whitespace on all five branches; run the hub micro-contract validation.
  4. Create atomic Conventional Commits per concern on each target branch, then record one completion row on `main` and promote `[06.5]` to `READY FOR PLANNING`; remove temporary worktrees.
- **Pending Scope Approval:** Brownfield injection installs the new `AGENTS.md` and Invariant 7 but omits `.agent/skills/interface-testing/SKILL.md`, leaving a broken on-demand reference in generated projects. Extend the branch-specific mutable paths with `brownfield:install.sh`; create the skill directory and add `skills/interface-testing/SKILL.md` to the existing `AGENT_FILES` installation loop, preserving local/remote download behavior and overwrite semantics. Add generated-project skill/invariant assertions in `main:.github/scripts/assert-starter-contracts.sh` and rerun all per-starter targets plus focused Brownfield install/reinstall checks.
- **Verification State:** Canonical skill and Invariant 7 parity, branch-specific contract preservation, mutable-path boundaries, relative links, branch targets, whitespace, all five per-starter suites, and 15 micro-contract self-tests passed. The combined suite is blocked by the pre-existing drift check requiring obsolete `free-fast`/`free-deep` aliases on `main`; address that mismatch during `[06.5]`.
- **Partial Implementation Commits:** greenfield: `2284fd2`, `400af02`; brownfield: `41bd28f`, `6dd7837`; blackbox: `cc3c3b7`, `2ee9d2f`; infra: `8c4d19f`, `7d05bb3`; baremetal: `a707839`, `9e700a0`
- Read:
  - AGENTS.md
  - .agent/TASK.md
  - .agent/INVARIANTS.md
  - .agent/skills/interface-testing/SKILL.md
- Paths:
  - AGENTS.md
  - .agent/INVARIANTS.md
  - .agent/skills/interface-testing/SKILL.md
- Verify: ./.github/scripts/verify-microcontract.sh verify-file .agent/TASK.md && git diff --check

---

## Completed Tasks Log

> Cycles 00–01 archived in `.agent/ARCHIVE.md` (up to `[v1.2.0]`). Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[02.1]` | Next Milestone / Epic Planning (Epic 02: Multi-Agent Orchestration) | `f948d2b` (main) | 2026-11-06 |
| `[02.2]` | Subagent Role Taxonomy & Delegation Specifications | `4b29226` (main), `00938fa` (greenfield), `a2f8753` (brownfield) | 2026-11-06 |
| `[02.3]` | Isolated Worktree & Sandbox Runner Integration | `d1753a6` (main), `2b55129` (greenfield), `6bf2819` (brownfield) | 2026-11-06 |
| `[02.4]` | Micro-Contract & Parallel Wave Validation in CI | `8a0d4b9` (main) | 2026-11-06 |
| `[02.5]` | Multi-Account Quota Failover Guidance & Starter Parity | `fad418d` (main), `0be4bb8` (greenfield), `674cabc` (brownfield), `6a1b9be` (blackbox), `f4b17b4` (infra), `2aa114e` (baremetal) | 2026-11-06 |
| `[03.1]` | Milestone 03 Roadmap: Starter Parity & End-to-End Test Harness | `6f84831` (main) | 2026-11-06 |
| `[03.2]` | Starter Branch Parity: Synchronize Multi-Agent & Quota Contracts | `3e06e6e` (greenfield), `7ac084a` (brownfield), `ed98cb8` (blackbox), `365af38` (infra), `9248fe8` (baremetal) | 2026-11-06 |
| `[03.3]` | Automated Scaffolding & CLI Contract E2E Validation in CI | `e6ac4d6` (main) | 2026-11-06 |
| `[03.4]` | Subagent Execution & Micro-Contract Validation Runner | `b89c49c`, `07eaaf7` (main) | 2026-11-06 |
| `[03.5]` | Epic 03 Milestone Consolidation & Audit | `71b3eab`, `6c5104d` (main) | 2026-11-06 |
| `[04.1]` | Next Milestone / Epic Planning (Epic 04: Dynamic Agent Sandbox & Security Hardening) | `cbe426d` (main) | 2026-11-06 |
| `[04.2]` | Hermetic Ephemeral Container & Bubblewrap Sandbox Specification | `35816cf` (main) | 2026-11-06 |
| `[04.3]` | Pre-Execution Security Scanner & Command Blast-Radius Audit Runner | `bade493`, `1a9c7e1` (main) | 2026-11-07 |
| `[04.4]` | Multi-Starter Parity: Propagate Sandbox & Security Isolation Contracts | `cd54c82` (greenfield), `d7e696b` (brownfield), `934ecd6` (blackbox), `55a625f` (infra), `2abaab2` (baremetal), `0e34b0c` (main) | 2026-11-07 |
| `[04.5]` | Epic 04 Milestone Consolidation & End-to-End Security Validation | `a4d2ddd`, `2dd4c15` (main) | 2026-11-07 |
| `[04.6]` | T3 Code Worktree Fast-Link Bootstrap & Project Lifecycle Hook Parity | `ff0e3ff`, `7069689`, `4d45aa2`, `010f689`, `b77cfd1`, `5758919` (main), `a4b56cf` (greenfield), `0c3996a` (brownfield), `788ea43` (blackbox), `b7909ed` (infra), `2ebb795` (baremetal) | 2026-11-07 |
| `[05.1]` | Next Milestone / Epic Planning (Epic 05: LLM Gateway & Virtual Model Routing) | `cd7f3c8` (main) | 2026-11-07 |
| `[05.2]` | LLM Gateway & Virtual Model Specification | `3197f9f` (main) | 2026-11-07 |
| `[05.3]` | Deterministic LLM Gateway Contract Linter & Pre-Flight Probe Runner | `ed9a166`, `3ab211c` (main) | 2026-11-07 |
| `[05.4]` | Starter Template Parity: Propagate LLM Gateway Contracts & `.env.example` | `cf6bbb9`, `b6470aa` (main), `06093c6` (greenfield), `688c59e` (brownfield), `dc6e47f` (blackbox), `e454f8b` (infra), `558e6d2` (baremetal) | 2026-11-07 |
| `[05.5]` | Epic 05 Milestone Consolidation, Documentation & Multi-Branch CI Audit | `0f63c18`, `0f036b0`, `dda3d0e` (main) | 2026-11-07 |
| `[06.1]` | Next Milestone / Epic Planning (Epic 06: Adaptive Interface Verification & Governance Automation) | `9ba6bb1` (main) | 2026-11-08 |
| `[06.2]` | Standardize Adaptive Interface Verification & On-Demand Skill | `fbc114b` (main) | 2026-11-08 |
| `[06.3]` | Ecosystem Governance Audit & Migration Tooling | `389b739` (main) | 2026-11-08 |

---

## Backlog (Upcoming, in priority order)

- `[06.5]` Epic 06 Milestone Consolidation, Documentation & Multi-Branch CI Audit



---

## Release / Cycle Wrap-up (Not the next task)

Release/tag only with explicit human request. When triggered, the ID is `[99.1]`. Do not number feature, hygiene, or CI tasks as `99.x`. Do not calculate next task ID from this section.

---

## Future Backlog / Ideas (Unprioritized)

*(empty)*

---

## How to Keep this File Lean

1. Detail only in the active task. When complete $\rightarrow$ log one line (title + hash) and promote next task.
2. Backlog is a list of titles. Full spec only when an item becomes the active task.
3. Large scope $\rightarrow$ issue in tracker; link only here.
4. Next ID = last ID in log (or active task). Cycle wrap-up and `[99.1]`: see `AGENTS.md`.
5. Do not paste full commit messages into this file. Deep history: `git log` / `.agent/NOTES.md`.
