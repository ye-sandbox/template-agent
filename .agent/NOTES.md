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

### 2026-09-03 Adoção da Estratégia de Branches como Templates

- **Contexto:** Manter múltiplos templates dentro de pastas no mesmo repositório gerava complexidade de exportação, poluição do diretório raiz e dificultava a clonagem limpa por desenvolvedores.
- **Decisão:** Adotada a estratégia de **Branches Especializadas como Templates**:
  - `main`: Hub central de documentação e governança.
  - `greenfield`: Starter kit para projetos do zero na raiz.
  - `brownfield`: Template para projetos legados com instalador na raiz.
- **Alternativas consideradas:** Manter subpastas `templates/` (descartado por forçar o usuário a copiar pastas manualmente ou ter árvore inflada).
- **Consequências:** Usuários podem clonar diretamente com `git clone -b greenfield ...` ou usar o script da branch `brownfield`, obtendo repositórios 100% limpos desde o primeiro commit.

### 2026-09-03 Suporte a Execução Remota via Pipe e Idempotência no install.sh (Brownfield)

- **Contexto:** O instalador one-liner `curl -fsSL ... | bash` falhava ao tentar copiar arquivos locais inexistentes e travava ao tentar ler confirmações interativas de sobrescrita pelo `stdin` consumido pelo bash.
- **Decisão:** O `install.sh` foi refatorado para:
  1. Detectar automaticamente se opera em modo local (cópia de arquivos existentes em `$SCRIPT_DIR`) ou modo remoto (download via `curl -fsSL` dos arquivos raw do GitHub).
  2. Permitir customização da URL base via variável `TEMPLATE_REPO_URL` (garantindo compatibilidade com forks e mirrors privados).
  3. Ler confirmações interativas diretamente de `/dev/tty` quando executado via pipe.
  4. Suportar flags `-y` / `--yes` / `--force` para automações e CI.
  5. Corrigir as URLs do repositório canônico para `ye-sandbox/template-agent`.
- **Consequências:** O comando one-liner do README para legados passa a funcionar de forma confiável e idempotente.

### 2026-09-03 Adição de Skills Canônicas de Referência (Greenfield)

- **Contexto:** Apenas o template vazio `000-template.md` não era suficiente para demonstrar a profundidade e o rigor exigidos em procedimentos operacionais de agentes de IA.
- **Decisão:** Foram criadas duas habilidades canônicas de referência em `.agent/skills/` na branch `greenfield`:
  1. `database-migration`: Procedimento com padrão *Expand and Contract*, obrigatoriedade de rollback testado (`up -> down -> up`) e atualização de contratos.
  2. `api-endpoint`: Procedimento de arquitetura desacoplada (Router fino -> Service puro -> Repository) com tipagem estrita de schemas e testes de integração automatizados.
  Ambas foram adicionadas ao catálogo do `AGENTS.md` e do `README.md` de skills da branch `greenfield`.
- **Consequências:** Usuários e agentes contam com modelos reais de alta fidelidade para orientar o desenvolvimento ou adaptar à sua stack específica.

### 2026-09-03 Criação do Inicializador Rápido One-Liner (Greenfield)

- **Contexto:** Desenvolvedores precisavam digitar múltiplos comandos manuais (`git clone -b greenfield ...`, `cd ...`, `git remote remove origin`, etc.) para iniciar um projeto, correndo o risco de herdar o histórico de commits do template.
- **Decisão:** Criado o script `init.sh` na branch `greenfield` que:
  1. Clona a branch de forma rasa (`--depth 1`).
  2. Remove o `.git` do template e executa `git init -b main`, criando um primeiro commit limpo (`chore: initial agent-driven development setup`).
  3. Remove o próprio script `init.sh` do projeto gerado para mantê-lo livre de resíduos de scaffold.
  4. Suporta execução remota via `curl -fsSL ... | bash -s -- meu-projeto` e flags `-y`/`-f`.
- **Consequências:** Adoção simplificada para um único comando no terminal, garantindo repositórios novos com histórico 100% limpo desde o primeiro segundo.

### 2026-09-03 Configuração de CI com GitHub Actions para Starters e Markdown

- **Contexto:** Necessidade de garantir que alterações futuras no repositório não quebrem os instaladores (`init.sh` e `install.sh`), nem deixem links quebrados ou markdowns inválidos nas branches especializadas.
- **Decisão:** Configurado workflow `.github/workflows/ci.yml` na branch `main`:
  1. `test-installers`: Testa a criação completa de projetos Greenfield (verificando scaffolding, skills e reset do Git) e a injeção em bases Brownfield (verificando idempotência e arquivos base).
  2. Execução hermética: O teste de `init.sh` utiliza o repositório local do runner (`TEMPLATE_REPO_URL="$GITHUB_WORKSPACE"`), garantindo testes rápidos, determinísticos e sem dependência de commits já publicados no GitHub.
  3. `lint-markdown`: Varre todos os arquivos Markdown do repositório garantindo que nenhum documento vazio ou corrompido seja commitado.
- **Consequências:** Regressões em scripts de automação são bloqueadas automaticamente antes de merge em `main`, `greenfield` ou `brownfield`.

### 2026-09-03 Protocolo de Sincronização Inter-Branches e Suporte a Forks

- **Contexto:** Por manter templates especializados com árvores de arquivos distintas na raiz de cada branch, comandos ingênuos como `git merge` entre branches de templates causariam poluição de arquivos e quebra estrutural. Além disso, forks privados necessitam apontar para repositórios próprios sem reescrever scripts.
- **Decisão:**
  1. Formalizada no `AGENTS.md` a proibição expressa de `git merge` entre branches de templates.
  2. Padronizado o uso de `git cherry-pick <hash>` para backports de governança e `git checkout <branch> -- <file>` para sincronização pontual de arquivos comuns.
  3. Formalizada a parametrização via `TEMPLATE_REPO_URL` em `init.sh` e `install.sh`, permitindo o consumo de forks no GitHub Enterprise, GitLab ou servidores locais.
- **Consequências:** Governança inter-branches protegida contra poluição acidental e suporte nativo a ambientes corporativos e privados.

### 2026-09-03 Política Estrita de No-Push para Código Legado (Brownfield)

- **Contexto:** Em bases de código existentes e em produção, permitir que agentes de IA enviem código diretamente para repositórios remotos (`git push`) traz riscos inaceitáveis de disparar pipelines de CI/CD ou deploys prematuros.
- **Decisão:** Formalizada no `AGENTS.md` da branch `brownfield` a regra de que o agente pode commitar localmente se autorizado pelo usuário, mas é **terminantemente proibido de executar `git push`**. O envio para branches remotas, staging ou produção é uma atribuição exclusivamente humana após revisão manual dos diffs.
- **Consequências:** Estabelecida uma barreira de proteção indispensável para a segurança de repositórios legados em produção.

### 2026-09-04 Criação da Branch Especializada de Infraestrutura e Serviços (infra)

- **Contexto:** Os templates existentes (`greenfield`, `brownfield`, `blackbox`) foram concebidos com premissas de código de aplicação (rotas HTTP, testes unitários, migrations de banco). Quando utilizados para provisionar serviços de infraestrutura (ex: Docker Compose, VictoriaLogs, Uptime Kuma, bancos de dados e observabilidade), os agentes falhavam por falta de guardrails sobre conflito de portas no host, persistência de volumes, isolamento de redes e limites de recursos.
- **Decisão:** Criada a quarta branch especializada de template: **`infra`**, com:
  1. Fonte canônica de topologia em `.agent/SERVICES.md` (portas alocadas no host, persistência de volumes, redes virtuais e healthchecks).
  2. Procedimento operacional padronizado em `.agent/skills/compose-service/SKILL.md`.
  3. Regras de ouro estritas para infra no `AGENTS.md` (proibição de senhas em YAML, proibição de `docker compose down -v`, obrigatoriedade de healthchecks e limites de memória/CPU).
  4. Script de inicialização rápida `init.sh` e `compose.yaml.example`.
  5. Testes automatizados herméticos integrados no CI (`.github/workflows/ci.yml`).
- **Consequências:** O ecossistema passa a cobrir formalmente a gestão de infraestrutura orientada a agentes com isolamento completo e sem poluir os starters de aplicação.

### 2026-09-04 Formalização do Protocolo de Higiene e Sanitização Pós-Release

- **Contexto:** Dúvidas comuns no ciclo de vida de projetos orientados a agentes sobre quando e como sanitizar a documentação após o corte de uma versão (ex: `v0.1.0`), e se o lançamento de releases estaria rigidamente condicionado à fase de Hardening `99.x`.
- **Decisão:** Desacoplar a release de numeração rígida de fases. A release é um evento do produto disparado por Tag Git que pode ocorrer em qualquer ciclo (ex: MVP em `01.3` ou hotfix emergencial). Foi formalizado em todas as branches (`main`, `greenfield`, `brownfield`, `blackbox`, `infra`) o protocolo de 4 etapas:
  1. **Arquivamento em lote:** Transferência das tarefas do marco para `.agent/ARCHIVE.md` sob o cabeçalho canônico `## [vX.Y.Z] - AAAA-MM-DD`.
  2. **Higiene e consolidação:** Promoção de contratos/ADRs definitivos e descarte de dados efêmeros de depuração no `.agent/NOTES.md` (ou `INVARIANTS.md`).
  3. **Sincronia de borda:** Validação estrita do `.env.example`, documentação de portas e `README.md`.
  4. **Reset do ciclo:** Promoção da próxima meta de negócio no `TASK.md` com status `PRONTO PARA PLANEJAMENTO`.
- **Consequências:** Prevenção garantida contra inchaço de contexto em todas as sessões de agentes de IA, com histórico preservado sem poluir a memória ativa.

### 2026-09-05 Reset de Numeração de Tarefas por Release e Âncora Padrão [99.1]

- **Contexto:** Risco de identificadores de tarefas acumularem valores contínuos excessivos (ex: `[150.2]`) e agentes alucinarem sobre quando ou como encerrar ciclos de entrega ou dispararem cortes de versão de forma autônoma.
- **Decisão:**
  1. **Reset do Contador por Release:** A cada corte de tag Git e arquivamento em lote no `ARCHIVE.md`, o contador do `TASK.md` recomeça a partir de `[00.1]` (ou `[01.1]`). Se houver uma tarefa ativa remanescente no momento do corte, seu identificador é corrigido para o novo ciclo. A regra de imutabilidade de histórico é delimitada pelo escopo da release no `ARCHIVE.md`.
  2. **Âncora Padrão `[99.1]` no Backlog Futuro:** Inclusão fixa nos templates de: `- [ ] **[99.1]** Preparar Release (Tag Git) e Sanitizar Contexto (Apenas executar com permissão explícita do usuário)`. Serve como guia visual para agentes identificarem o encerramento do ciclo, com trava explícita de permissão humana obrigatória no `AGENTS.md`.
- **Consequências:** Numeração sempre concisa e previsível por versão (`00.x` a `99.x`), com salvaguarda ativa contra execuções não autorizadas de release por agentes.

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
