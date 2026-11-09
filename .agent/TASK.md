# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[07.3]` Ecosystem Auditor: Verify Adaptive Interface Contracts
- **Status:** RUNNING
- **Scope:** Extend ecosystem compliance reports with explicit checks for the installed interface-testing skill, all four Invariant 7 guardrails, and runtime-aware UI context/DoD directives. Preserve existing CLI flags and report fields; document any scoring changes during planning.
- **Target Branches:** `main` only; validate using disposable fixtures.
- **Approved Plan:**
  1. Implement within an isolated checkout of `main`, changing only the auditor, its hermetic tests, and task bookkeeping. Read canonical interface references from this hub's `.agent/skills/interface-testing/SKILL.md` and `.agent/INVARIANTS.md`, not from the audited repository. Missing/unreadable references must produce explicit failed checks/diagnostics rather than silently passing.
  2. Add eight Boolean checks: installed skill (weight 2), byte-for-byte canonical skill parity (4), each of Invariants 7.1-7.4 (2 each), an on-demand skill reference in the active AGENTS context section (3), and a UI verification DoD containing both T3 Code and headless paths (3). Compare each invariant's actual guardrail block with the corresponding canonical block, allowing unrelated project invariants outside those blocks; labels or fenced examples alone must not satisfy checks.
  3. Preserve all existing CLI flags, top-level report fields, existing check keys, tier thresholds, and `--fail-under` semantics. Retain existing weights and add 20 interface points, increasing the maximum from 100 to 120; score remains the rounded percentage. A previously 100% fixture missing every interface contract becomes 83%, while a fully conforming fixture remains 100%. New failed checks add actionable violations visible in existing report/verbose paths. Record this scoring change in code and tests; bilingual user documentation follows in `[07.5]`.
  4. Extend the existing `--self-test` suite with conforming fixtures, each missing/drifted contract, altered skill bytes, duplicate or fake/fenced invariant labels, irrelevant AGENTS references, unavailable canonical references, and unreadable/malformed inputs. Verify read-only behavior, score calculations, JSON/report field compatibility, and CLI threshold exit codes using disposable fixtures only.
  5. Run auditor self-tests, Python syntax compilation, the hub audit with the existing CI threshold of 90, micro-contract validation, changed-link/branch-target checks, and `git diff --check`. Commit code/tests separately from lifecycle bookkeeping, log `[07.3]` completion, promote `[07.4]` to `READY FOR PLANNING`, and remove the temporary worktree.
- **Role:** Worker
- **Isolation:** worktree
- **Acceptance Criteria:**
  - Reports identify missing or drifted interface skills, invariant guardrails, and context/DoD directives through explicit checks.
  - Conforming fixtures pass; each missing/drifted fixture fails its relevant checks.
  - Existing CLI flags and report fields remain compatible; any scoring changes are specified and tested.
  - Existing auditor self-tests and micro-contract validation pass; specialized branches remain unchanged.
- Read:
  - AGENTS.md
  - .agent/TASK.md
  - .agent/NOTES.md
  - .agent/INVARIANTS.md
  - .agent/skills/interface-testing/SKILL.md
  - docs/adr/decisions.md
  - .github/scripts/audit-ecosystem-standards.py
- Paths:
  - .github/scripts/audit-ecosystem-standards.py
  - .github/scripts/tests/
  - .agent/TASK.md
- Verify: python3 .github/scripts/audit-ecosystem-standards.py --self-test && ./.github/scripts/verify-microcontract.sh verify-file .agent/TASK.md && git diff --check

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
| `[06.5]` | Epic 06 Milestone Consolidation, Documentation & Multi-Branch CI Audit | `ce88799`, `ed72284` (main) | 2026-11-08 |
| `[07.1]` | Next Milestone / Epic Planning: Safe Ecosystem Adoption & Interface Compliance | `7175590`, `9083747` (main) | 2026-11-08 |
| `[07.2]` | Lossless Governance Migration: Preserve ADR Assets & Decision Content | `d3c3623` (main) | 2026-11-08 |

---

## Backlog (Upcoming, in priority order)

- `[07.4]` Opt-In Interface Contract Migration
- `[07.5]` Epic 07 Consolidation, Documentation & CI Audit



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
