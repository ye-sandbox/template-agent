# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[05.3]` Decouple Baremetal: Replace Node.js with Native Bash Test Runner (`tests/smoke.sh`)
- **Status:** RUNNING
- **Scope:**
  - Branch `baremetal`: Remove Node.js coupling (`package.json`, `tests/smoke.test.js`) and introduce pure native bash test runner `tests/smoke.sh`.
  - Branch `baremetal`: Update `AGENTS.md` validation commands to use `./tests/smoke.sh`.
  - Branch `main`: Update CI assertions in `.github/scripts/assert-starter-contracts.sh` for `baremetal`.
  - Verification: Run `.github/scripts/test-all-starters.sh baremetal` and `.github/scripts/test-all-starters.sh all`.
- **Target Branches:** `baremetal`, `main`

---

## Completed Tasks Log

> Cycles 00–20 archived in `.agent/ARCHIVE.md` (up to `[v1.0.0]`). Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[01.1]` | Standardize In-Code Invariants across Starter Templates | `02270d7`, `d5a6a88`, `c1d8622`, `ba297fb`, `fc16dbd`, `8574f8b`, `873f942`, `58505d0` | 2026-10-19 |
| `[01.2]` | Post-v1.0.0 Foundation & Starter Ecosystem Roadmap | `93d60be`, `d71f854` | 2026-10-19 |
| `[01.3]` | Active Starter Smoke Testing Assertions in CI Workflow | `b46342f` | 2026-10-19 |
| `[02.1]` | Harmonize ADR Diary (`docs/adr/decisions.md`) across Infra & Baremetal Starters | `a6fd941`, `5ff38cf`, `38cbd0c`, `45f5c96` | 2026-10-19 |
| `[02.2]` | Standardize Service Topology Template (`.agent/ECOSYSTEM.md`) in Infra Starter | `cef169a`, `5fb9546`, `5b7fa3f` | 2026-10-19 |
| `[03.1]` | Pre-Seed Canonical Knowledge Base Cards across Starters | `006db0e`, `577dbe7`, `0e28c34`, `05e8fb4`, `86caa2b` | 2026-10-19 |
| `[03.2]` | Pre-Seed Canonical Knowledge Base Cards in Brownfield & Blackbox Starters | `5f963f5`, `3b20bd2`, `c6773e3`, `56370e1` | 2026-10-19 |
| `[04.1]` | Unified Multi-Starter Local & CI Test Runner Script | `ccbddd4` | 2026-10-19 |
| `[04.2]` | Language-Agnostic Greenfield Decoupling and CI Contract Calibration | `0a172d1`, `1fab7e1` | 2026-10-19 |
| `[04.3]` | Consolidate ADR Architecture on decisions.md and Purge .agent/adr Residue | `3d73da5`, `09194e7` | 2026-10-19 |
| `[05.1]` | Purge Residual .agent/adr References Across Starters and Sync Documentation | `86de3d9`, `d86b6c3`, `5065bc2`, `87f670a`, `94cb7bf`, `47dd652` | 2026-10-20 |
| `[05.2]` | Decouple Greenfield: Remove Boilerplate Skills and Add `--standalone` Flag in `init.sh` | `91b169b`, `6416052`, `1b65a40`, `56e0f47`, `7b1456a`, `2033b06` | 2026-10-20 |

---

## Backlog (Upcoming, in priority order)

1. `[05.4]` Decouple Blackbox: Language-Agnostic Scaffolding & Zero-Dependency Validation
2. `[05.5]` Hub Governance: Inter-Branch Drift Detection Script and CLI Flags Standardization

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
