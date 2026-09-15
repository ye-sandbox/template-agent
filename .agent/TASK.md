# TASK.md — Current Task and Roadmap
 
> Defines WHAT needs to be done. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.
> 
> **Golden rule of this file:** It stores WHAT TO DO, not WHAT WAS DONE.
> Implementation details of completed tasks live in `git log`, not here.

---

## Active Task

### 📌 Task [XX.Y]: [Short descriptive title]

- **Description:** [2–4 lines for the agent to assemble a plan.]
- **Systems Involved:** [e.g.: `docs`, `hub`, `branch-greenfield`]
- **Action Type:**
  - [ ] Read-only / Documentation
  - [ ] Source code changes
- **Status:** READY FOR PLANNING
  *(Workflow: `READY FOR PLANNING` → `PLANNING` on presenting plan → approval → `RUNNING`)*

### Acceptance Criteria
- [ ] [Verifiable criterion 1]
- [ ] [Verifiable criterion 2]

---

## Completed Tasks Log

> Cycles 00–03: `.agent/ARCHIVE.md`. Detail: `git log`.

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| [04.1] | Enxugar guardrails e corrigir incoerências de contexto | [`b25715e`, `d615950`, `254a3ef`, `2bdd0eb`, `2ea2d63`, `0231b5e`, `58a1fc3`, `376adbc`, `ae7c529`, `4c6c90c`, `6b2a7e4`] | 2026-09-06 |
| [04.2] | Asserções de contrato no CI dos starters | [`c582fd1`, `0397624`, `e575ec0`] | 2026-09-06 |
| [04.3] | Enxugar leftovers de contexto | [`2621de4`, `c9acedd`, `9747f16`, `19d2c08`, `f0a0619`, `5172f7b`, `eadb9e9`, `dbdecb7`, `375407c`] | 2026-09-06 |
| [04.4] | Extrair asserções de contrato do CI para um script | [`06c3416`, `bb50e90`] | 2026-09-06 |
| [04.5] | Sucessão de IDs a partir do log, não do [99.1] | [`714b8ed`, `4308eb7`, `9abad68`, `09352d1`, `6e15adf`] | 2026-09-07 |
| [05.1] | Skill `ui-contract` (requisitos de UI a partir do backend) | [`3ab12cd`, `c599aaf`] | 2026-09-08 |
| [05.2] | Chrome de tema e política de locale na `ui-contract` | [`d0233c8`] | 2026-09-08 |
| [05.3] | Pipeline UI (`ui-prototype`, `ui-port`, delta) | [`8cc03cd`] | 2026-09-08 |
| [05.4] | Skill `component-contract` (inventário de componentes, não telas) | [`51e134d`, `47bef3a`] | 2026-09-10 |
| [05.5] | `ui-port` / `ui-prototype` aceitam proto Stitch (`code.html`) | [`6d5fa9b`] | 2026-09-10 |
| [05.6] | Idioma Svelte 5 (runes + peças) no `ui-port` | [`45ad5d6`, `43c6d9b`] | 2026-09-10 |
| [05.7] | Fidelidade de `class`/grid/motion no `ui-port` | [`d72ac8b`, `7703859`, `da1a756`] | 2026-09-10 |
| [05.8] | Guardrails de peça, CSS utilitário e padrão de tela no `ui-port` | [`e9c3651`] | 2026-09-13 |
| [05.9] | Superfície de UI no `ui-contract` (audiência, densidade, motion, copy, formato) | [`deafb06`] | 2026-09-13 |
| [05.10] | Skill `qa-environment` (Mock, Seeding, Túnel e Prompt) | [`1a08274`] | 2026-09-13 |
| [06.1] | Extrair playbooks transversais para `agent-skills` | [`94f562a`] | 2026-09-13 |
| [07.1] | Starters and Hub internationalization (Technical English + PT-BR README) | [`e748b7c`, `567fd62`, `a54b465`, `9e0a8d5`, `06103f4`] | 2026-09-15 |

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
