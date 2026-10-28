# TASK.md — Current Task and Roadmap

> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

- **Task:** `[09.1]` Starter Ecosystem Pre-Release Validation and Final Readiness
- **Status:** READY FOR PLANNING
- **Scope:**
  - Auditar integridade final dos starters, documentação pública e preparar alinhamento para publicação do release.
- **Target Branches:** `main`, `all branches`

---

## Completed Tasks Log

> Cycles 00–20 archived in `.agent/ARCHIVE.md` (up to `[v1.0.0]`). Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[08.4]` | Safe Git History Purge and Identity Neutralization Across All Branches | `9768c9c` | 2026-10-28 |
| `[08.3]` | Generalize Observability Stack References Across Starters | `271fdbe`, `5e9b14a`, `d733420` | 2026-10-28 |
| `[08.2]` | Neutralização de Identificadores Pessoais e Mocks do Domínio SEI | `5db8cf4`, `7612507`, `23337eb` | 2026-10-27 |
| `[08.1]` | Generalize Skills Directory and Decouple Private Links across Hub and Starters | `efdbd7a`, `9ff4bd9`, `336ee3f` | 2026-10-27 |
| `[07.4]` | Standardize Healthcheck Endpoint and Probe Log Discarding Across Starter Templates | `86c95bd`, `699d7b6`, `6482a7b` | 2026-10-27 |
| `[07.3]` | Standardize Market-Grade Product README Scaffolding & Governance Across Starters | `828e4c9`, `6e9c15e`, `241d8a5`, `b9c4ada`, `1087889`, `38d711f`, `88d6b1b` | 2026-10-25 |
| `[07.2]` | Fix Brownfield Stealth Path Resolution for macOS Symlinks in CI/CD | `b7617d3` | 2026-10-24 |
| `[07.1]` | Decouple Starter Templates from Maestri Tooling to Tool-Agnostic Runtime Contracts | `abe7ba4`, `6b742b8`, `32197db`, `a885ac7`, `044723a`, `0ee86fa` | 2026-10-21 |
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
| `[05.3]` | Decouple Baremetal: Replace Node.js with Native Bash Test Runner (`tests/smoke.sh`) | `5d038d6`, `e6e1ce3`, `26be8d7`, `f4653b8` | 2026-10-20 |
| `[05.4]` | Decouple Blackbox: Language-Agnostic Scaffolding & Zero-Dependency Validation | `a18dcfe`, `2376be3`, `78da786`, `e4d493e` | 2026-10-20 |
| `[05.5]` | Hub Governance: Inter-Branch Drift Detection Script and CLI Flags Standardization | `495ba99`, `0e37a52`, `750b4bb`, `260d36c`, `eee5ee1`, `9cb3082`, `be492e9`, `6ab87fb`, `bbd087e`, `0a0fb7b`, `bf102f7`, `4021a07` | 2026-10-20 |
| `[06.1]` | Starter Onboarding Harmonization: Standardize First-Turn Prompts and Post-Scaffolding Flow | `38e812c`, `3af681a`, `124781b`, `6756652`, `7e824fe`, `bcf5f6b`, `29db81b`, `b81226d` | 2026-10-20 |
| `[06.2]` | Cross-Platform CI Matrix: Scaffolding Assertions on Ubuntu & macOS Runners | `6e2ade2`, `6307fae`, `31c4173`, `9b69bb7`, `eb5293a`, `d022134`, `efce79c` | 2026-10-20 |

---

## Backlog (Upcoming, in priority order)

*(empty — all cycle 08 tasks promoted or completed)*


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
