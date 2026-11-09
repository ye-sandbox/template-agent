# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[06.5]` Epic 06 Milestone Consolidation, Documentation & Multi-Branch CI Audit
- **Status:** READY FOR PLANNING
- **Scope:** Consolidate Epic 06 documentation and audit CI across all starter branches. Resolve the pre-existing gateway-alias drift check requiring `free-fast`/`free-deep` on `main`, whose canonical routing contract uses `fast`/`deep`; verify interface contract coverage and run the combined starter suite.
- **Target Branches:** `main` (hub documentation and CI); specialized starter branches only if approved during planning.
- **Role:** Worker
- **Isolation:** worktree
- Read:
  - AGENTS.md
  - .agent/TASK.md
  - .agent/NOTES.md
  - .agent/INVARIANTS.md
  - .github/workflows/ci.yml
  - .github/scripts/check-branch-drift.sh
  - .github/scripts/assert-starter-contracts.sh
- Paths:
  - .agent/TASK.md
  - README.md
  - README.pt-br.md
  - CHANGELOG.md
  - docs/
  - .github/workflows/
  - .github/scripts/
- Verify: ./.github/scripts/verify-microcontract.sh verify-file .agent/TASK.md && ./.github/scripts/test-all-starters.sh && git diff --check

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
| `[06.4]` | Starter Template Parity: Propagate Interface Verification & Invariants | `2284fd2`, `400af02` (greenfield); `41bd28f`, `6dd7837`, `358db7e` (brownfield); `cc3c3b7`, `2ee9d2f` (blackbox); `8c4d19f`, `7d05bb3` (infra); `a707839`, `9e700a0` (baremetal); `84c47a5` (main) | 2026-11-08 |

---

## Backlog (Upcoming, in priority order)

*(empty)*



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
