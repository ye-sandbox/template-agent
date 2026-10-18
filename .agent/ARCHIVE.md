# ARCHIVE.md — Arquivo Histórico de Tarefas Concluídas

> Lotes arquivados após tag Git ou quando o log do `TASK.md` passar de ~15 linhas.
> Detalhe de implementação: `git log`.

---

## Ciclo 00–03 — arquivado 2026-09-06

Pré-release do hub (sem tag). IDs imutáveis neste bloco.

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| [00.2] | Refinar Template Core/Greenfield com Suporte a MCPs e Skills | [`031e7a6`] | 2026-09-03 |
| [00.3] | Criar Template Brownfield para Projetos Existentes | [`dc842f7`] | 2026-09-03 |
| [00.4] | Reorganizar Templates em Branches (main, greenfield, brownfield) | [`6df1e01`] | 2026-09-03 |
| [01.1] | Corrigir Execução Remota via `curl \| bash` no `install.sh` | [`7a0fd03`] | 2026-09-03 |
| [01.2] | Adicionar Exemplos Práticos de Skills de Projeto | [`2a0f61a`] | 2026-09-03 |
| [01.3] | Criar Script de Inicialização Rápida (One-Liner) para Greenfield | [`df6876e`] | 2026-09-03 |
| [01.4] | Configurar CI com GitHub Actions para Validação de Templates | [`dbbcc1c`] | 2026-09-03 |
| [01.5] | Documentar Protocolo de Sincronização e Suporte a Forks | [`e0513d0`] | 2026-09-03 |
| [02.1] | Padronizar Numeração de Tarefas e Criar Branch Blackbox | [`67b59fc`] | 2026-09-04 |
| [02.2] | Equalizar Commits Atômicos, Conventional Commits e Numeração [XX.Y] | [`387471a`] | 2026-09-04 |
| [03.1] | Criar Branch Especializada de Infraestrutura e Serviços (`infra`) | [`9f4de15`, `2e100f6`] | 2026-09-04 |
| [03.2] | Formalizar Protocolo de Higiene e Sanitização Pós-Release nos Templates | [`0a87934`, `1107c67`, `1abbfd6`, `fd0cf01`, `33df53d`] | 2026-09-04 |
| [03.3] | Padronizar Reset de Numeração por Release e Âncora [99.1] no Backlog Futuro | [`c310997`, `bab484d`, `efb6a89`, `a2da17c`, `abdb522`] | 2026-09-05 |

---

## [v1.0.0] - 2026-10-17

Ciclos 04–20 — Primeira release oficial do Template Hub.

| Tarefa | Título | Commit(s) | Data |
|---|---|---|---|
| [20.1] | Baremetal Continuous Observability: Stream Hardware Monitor & Latency Metrics to VictoriaLogs via Vector | [`7c2d69f`, `1a0d945`, `3afc350`, `62e3b7e`, `e8350ad`] | 2026-10-17 |
| [19.1] | Standardize Knowledge Base (.agent/knowledge/) and Schema Across Template Branches | [`382efe9`, `6a6905e`, `0af2716`, `0f4771e`, `e19535a`, `0d52363`, `bd3d2aa`, `0159bab`, `8c62122`, `6ae7aed`] | 2026-10-17 |
| [18.2] | Harmonize Brownfield and Blackbox Contracts with Greenfield Maturity | [`ca8197f`, `1d32d48`, `c2ff6cd`, `bbcfb1f`, `d3fefb0`] | 2026-10-14 |
| [18.1] | Multi-repo ecosystem topology template (.agent/ECOSYSTEM.md) and guardrails for brownfield | [`5cae3fc`, `1a5d86e`, `6f40138`] | 2026-10-10 |
| [17.3] | Calibrate Function Length and Cognitive Complexity Guardrails in Greenfield Starter | [`81c6c4e`, `b6119f3`, `b9d1f40`] | 2026-10-10 |
| [17.2] | Latest Stable and LTS Dependency Versioning Directives Across Starters | [`1f45d1d`, `fe49da6`, `bab0d1e`, `d94dfa0`] | 2026-10-10 |
| [17.1] | Consultative Dependency Trade-offs in Greenfield and Brownfield Starters | [`b473c60`, `4142f6b`, `cde10b3`, `c452bc3`] | 2026-10-10 |
| [16.2] | Baremetal Benchmark & Telemetry Harness Structure (`benchmarks/`, `.gitignore`, skill & contracts) | [`1590f6a`] | 2026-10-08 |
| [16.1] | Add Baremetal & Host Optimization Starter Template Branch (`baremetal`) | [`116aba9`, `4a081c5`, `7b6a874`, `66ba367`] | 2026-10-08 |
| [15.1] | Standardize Agent-Facing Documentation in Technical English Across Templates | [`8b39dc8`, `9f44ed0`, `66d2955`, `71ce354`, `55d5f67`, `3c504c1`] | 2026-10-08 |
| [14.1] | Starter Templates ADR Diary (`docs/adr/decisions.md`) and Active Contracts Isolation (`NOTES.md`) | [`2c28814`, `10b411d`, `444a058`, `434d9af`, `ad84677`] | 2026-10-05 |
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
| [08.1] | Apply 11 Agent Instruction-File Design Rules to Templates | [`bf8402b`, `bad0f7b`, `25e0b55`, `370beb5`, `c75131d`, `376fca0`] | 2026-09-15 |
| [09.1] | Standardize documentation taxonomy, RCA templates and author metadata header | [`4fc712f`, `50b59aa`, `28068cc`] | 2026-09-18 |
| [09.2] | Graduated incident management, preventive actions tracker, and VictoriaLogs anchors | [`6286035`, `e3ca0c1`, `131fd77`] | 2026-09-18 |
| [10.1] | Brownfield `--local-only` stealth mode for enterprise repositories | [`8f31440`, `27e3dac`, `6f3fd24`, `f521191`] | 2026-09-19 |
| [11.1] | Multi-repo ecosystem topology template (.agent/ECOSYSTEM.md) and guardrails for greenfield | [`e785269`, `e8e6be3`, `0a26fc7`] | 2026-09-30 |
| [12.1] | Baseline test runner pre-configuration and validation contracts for starters | [`b3b33fa`, `21c6195`, `bff3277`, `a53c84b`, `433ae43`] | 2026-10-01 |
| [13.1] | Ignore TypeScript incremental build cache and Maestri canvas state across template branches | [`8a76a8b`, `12e025f`, `27e37ce`, `b704d7f`, `e9bfc23`, `18ec689`, `5d575c0`] | 2026-10-01 |
