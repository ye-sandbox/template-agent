# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[07.5]` Epic 07 Consolidation, Documentation & CI Audit
- **Status:** PLANNING
- **Scope:** Consolidate safe ecosystem adoption tooling, document migration/audit CLI behavior in both READMEs, and validate CI coverage and starter compatibility.
- **Dependencies:** `[07.2]` lossless migration, `[07.3]` interface auditing, and `[07.4]` opt-in interface migration are complete.
- **Target Branches:** `main` only; inspect starter compatibility without changing specialized branch heads or migrating external projects.
- **Role:** Worker
- **Isolation:** worktree
- **Acceptance Criteria:**
  - CI runs the migration and auditor fixture suites, including opt-in preservation and conflict handling.
  - English and Portuguese documentation describe compatible default CLI behavior, opt-in interface adoption, dry-run, conflicts, and audit scoring.
  - Relevant starter, governance, and self-test suites pass; Markdown links and branch targets validate.
  - CHANGELOG and the cumulative ADR diary reflect the consolidated Epic 07 behavior without tagging a release.
- Read:
  - AGENTS.md
  - .agent/TASK.md
  - .agent/NOTES.md
  - .agent/INVARIANTS.md
  - docs/adr/decisions.md
  - README.md
  - README.pt-br.md
  - CHANGELOG.md
  - .github/workflows/ci.yml
  - .github/scripts/apply-governance-standards.py
  - .github/scripts/audit-ecosystem-standards.py
  - .github/scripts/tests/test_interface_migration.py
- Paths:
  - .github/workflows/ci.yml
  - README.md
  - README.pt-br.md
  - CHANGELOG.md
  - docs/adr/decisions.md
  - .agent/TASK.md
- Verify: python3 .github/scripts/apply-governance-standards.py --self-test && python3 .github/scripts/audit-ecosystem-standards.py --self-test && ./.github/scripts/verify-microcontract.sh verify-file .agent/TASK.md && git diff --check


### Proposed Implementation Plan (Pending Human Approval)

1. Work in an isolated worktree targeting `main`. In `.github/workflows/ci.yml`, make audit and migration fixture coverage explicit in the existing Ubuntu/macOS matrix, including compilation of the external interface fixture module. Retain the existing self-test entry points, audit threshold, starter validation, and full-history checkout; avoid duplicate suite execution.
2. Update the ecosystem tooling sections of `README.md` and `README.pt-br.md` in parallel translations. Document running from the hub checkout, repository selection and exclusions, compatible default migration behavior, explicit `--include-interface-contracts` adoption, dry-run before application, repeat-run behavior, preservation guarantees, manual conflict reconciliation and exit status, and read-only audit output/threshold options. Explain the legacy 100 plus interface 20 point normalization to 0–100, including the 83-point legacy-perfect case without interface contracts. Check examples against the actual parsers; use placeholders and disposable fixtures rather than external-project migrations.
3. Update `CHANGELOG.md` under Unreleased for lossless ADR migration, interface audit checks/scoring, opt-in migration, and fixture coverage. Append one Technical English consolidation decision to `docs/adr/decisions.md`, preserving its existing diary and documenting conservative adoption and compatibility boundaries.
4. Validate the migration and audit self-tests, hub audit threshold, micro-contract validator and isolation self-tests, security scanner, bootstrap lifecycle tests, LLM contract tests, branch-drift fixtures, and unified five-starter suite. Validate changed Markdown relative links and branch targets, workflow syntax and command coverage, and `git diff --check`. Local execution covers the available runtime; macOS execution remains a CI check. Apply the repository fail-stop protocol if a command fails three times with the same cause.
5. Create separate atomic Conventional Commits for CI, documentation/ADR, and task-state changes, with explanatory bodies where required. Log `[07.5]` completion and promote `[08.1]` Next Milestone / Epic Planning as planning-only work without preselecting feature scope.

**Execution boundary:** Only the declared mutable paths may change. Specialized branch heads and external projects remain unchanged. Release tagging and release-cycle resets require separate human instruction. Implementation awaits explicit approval of this plan.

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
| `[07.3]` | Ecosystem Auditor: Verify Adaptive Interface Contracts | `090ecc9` (main) | 2026-11-08 |
| `[07.4]` | Opt-In Interface Contract Migration | `0478087` (main) | 2026-11-08 |

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
