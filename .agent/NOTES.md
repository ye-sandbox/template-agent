# NOTES.md — Decisões, Contexto e Contratos do Projeto

> Guarda o PORQUÊ, não o QUE nem o COMO. Descrições de "o que foi feito" ficam no
> `git log` / commits. Passos de "o que fazer" ficam no `.agent/TASK.md`. Este arquivo é
> para decisões, trade-offs, contratos e armadilhas que **não são óbvias a partir do diff**.
>
> **Regra de ouro:** antes de escrever aqui, pergunte "isso explica uma decisão,
> ou só descreve uma mudança?". Se for só descrição, o commit message já resolve —
> não duplique aqui.

---

## Como usar este arquivo (para o agente)

1. **Leia antes de planejar qualquer tarefa.** Decisões registradas aqui têm
   precedência sobre "a forma óbvia de fazer" — presuma que já foi considerada e
   descartada por um motivo, a menos que o usuário peça para revisitar.
2. **Registre uma nova entrada quando:**
   - Uma escolha arquitetural foi feita entre duas ou mais alternativas plausíveis.
   - Um contrato de dados (payload, schema, nome de fila/rota, query/resposta de MCP) foi definido ou alterado.
   - Uma armadilha, limitação externa ou comportamento não-óbvio de uma lib/serviço/MCP
     foi descoberto (para não ser redescoberto/re-debugado no futuro).
   - Uma nova Skill de projeto foi criada ou um procedimento operacional foi padronizado.
   - Um débito técnico foi assumido conscientemente (e por quê).
3. **Não registre aqui:** listas de arquivos alterados, resumo de testes passando,
   changelog de features — isso é commit message / `.agent/TASK.md`.
4. **Mantenha as entradas curtas.** Se uma decisão precisa de um parágrafo enorme
   para ser justificada, considere um ADR separado em `.agent/adr/NNN-titulo.md` e
   deixe aqui só um link + resumo de uma linha.

---

## Decisões Arquiteturais e ADRs

> **Critério de separação:**
> - **Decisões Táticas Rápidas (locais):** Registre diretamente abaixo no formato resumido.
> - **Decisões Estruturais Complexas (globais):** Crie um arquivo em `.agent/adr/NNN-titulo.md` (usando `.agent/adr/000-template.md`) e liste na tabela de índice abaixo com o link correspondente.

### Índice de ADRs Formais (`.agent/adr/`)

| ADR | Título | Status | Data |
|---|---|---|---|
| [ADR-001] | [ex: Escolha do Banco de Dados Principal] | [Aprovado] | [AAAA-MM-DD] |

---

### Decisões Rápidas e Contexto Técnico

### 2026-09-03 Estruturação de Governança para MCPs e Skills de Projeto

- **Contexto:** Necessidade de padronizar como agentes acessam ferramentas externas (MCPs) e fluxos procedurais complexos (Skills) sem inflar o `AGENTS.md` ou gerar overhead cognitivo em tarefas corriqueiras.
- **Decisão:** Adotada a divisão canônica:
  1. `AGENTS.md`: regras inegociáveis, stack, autorizações de MCPs e catálogo de skills.
  2. `.agent/skills/<nome>/SKILL.md`: manuais procedurais passo a passo para o agente, isolando fluxos repetitivos de domínio com template padronizado (`000-template.md`).
  3. Skills de infraestrutura compartilhada (ex: VictoriaLogs, Proxmox) devem preferencialmente residir no escopo global do ambiente, enquanto skills locais tratam exclusivamente da aplicação.
- **Alternativas consideradas:** Centralizar tudo no `AGENTS.md` (descartado por poluição de contexto do agente e custo desnecessário de tokens) ou criar pastas dispersas (descartado por falta de padronização).
### 2026-09-03 Estruturação do Template Brownfield para Projetos Legados

- **Contexto:** Necessidade de disponibilizar um template especializado para introdução segura de agentes em bases de código existentes, sem correr riscos de regressão e sem o overhead de criar ADRs retroativas do passado.
- **Decisão:** Criada a suíte `templates/brownfield/` com os seguintes diferenciais em relação ao Core/Greenfield:
  1. Remoção da pasta `.agent/adr/` em favor de `.agent/INVARIANTS.md` (Princípio do Muro de Chesterton).
  2. Inclusão da regra obrigatória de "Testes de Caracterização" antes de refatorar código legado.
  3. Pré-configuração da Tarefa [00.1] de Auditoria e Discovery no `TASK.md`.
  4. Script de instalação one-liner `install.sh` para cópia segura em projetos existentes.
- **Alternativas consideradas:** Usar o mesmo template Greenfield para legados (descartado por induzir o agente a refatorações perigosas e perda de tempo tentando documentar ADRs antigas).
- **Consequências:** Estabelecida uma taxonomia clara: `Core` para projetos do zero e `Brownfield` para legados.

> Exemplo de preenchimento:
>
> ### [AAAA-MM-DD] [Padronização de comunicação entre Serviço A e Serviço B]
>
> - **Contexto:** [Divergência de contratos de payloads entre os serviços de ingestão e processamento.]
> - **Decisão:** [Definido contrato canônico centralizado `{ id: string, event: string, timestamp: number }`.]
> - **Alternativas consideradas:** [Manter adaptadores manuais por serviço — descartado por gerar redundância e fragilidade.]
> - **Consequências:** [Qualquer novo campo de payload deve ser versionado e refletido nos schemas de ambos os serviços.]

---

## Contratos de Dados Vigentes

> Fonte da verdade _resumida_ dos contratos entre serviços. O schema completo vive
> no código (ex: `core/schemas/` ou `schemas/`) — aqui é o mapa mental rápido para consulta.

### Comunicação / Filas / Eventos

| Canal / Tópico / Rota | Produtor | Consumidor | Payload (Schema) |
|---|---|---|---|
| `[ex: events:user:created]` | `[Serviço A]` | `[Serviço B]` | `[UserCreatedPayload]` |
| `[ex: commands:order:process]` | `[Serviço B]` | `[Serviço C]` | `[ProcessOrderPayload]` |

### Exemplo de Contrato Canônico

```json
{
  "id": "string",
  "type": "string",
  "created_at": "string (ISO8601)",
  "data": {}
}
```

> **Regra:** qualquer alteração de contrato exige atualização simultânea nos schemas
> dos serviços envolvidos, na mesma tarefa/commit.

---

## Armadilhas e Comportamentos Não-Óbvios

> Coisas que custaram tempo de debug e não devem ser redescobertas pelo agente.

- **[Nome da Lib/Serviço]:** [Descreva o comportamento inesperado e como contornar/mitigar].
- *Exemplo:* **[Banco de Dados / ORM]:** [Exemplo: consultas aninhadas geram problema N+1 se não usado `.select_related()` / `.include()`].
- *Exemplo:* **[Docker / Volumes]:** [Exemplo: permissões de escrita em volumes bind mount exigem UID mapeado no container].

---

## Débitos Técnicos Assumidos

| Débito | Motivo da decisão | Quando revisitar |
|---|---|---|
| `[ex: Sem retry exponencial na fila]` | `[ex: Escopo simplificado para MVP]` | `[ex: Antes do lançamento em produção]` |

---

## Referências Externas Relevantes

> Links de documentação de terceiros que influenciaram decisões (versões de API,
> rate limits, breaking changes) — para não depender só de memória de treinamento desatualizada.

- `[Nome da lib/API]` — `[link]` — `[nota curta sobre o que é relevante aqui]`
