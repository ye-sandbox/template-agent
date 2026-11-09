# template-agent

Hub de governança técnica e starters isolados por branch para engenharia de software colaborativa com agentes de IA.

**[English](README.md)** | **[Português (Brasil)](README.pt-br.md)**

[![CI](https://github.com/ye-sandbox/template-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/ye-sandbox/template-agent/actions)
[![Release](https://img.shields.io/github/v/release/ye-sandbox/template-agent?color=blue)](https://github.com/ye-sandbox/template-agent/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/license/mit)
[![Arquitetura: Starters Isolados](https://img.shields.io/badge/Arquitetura-Starters_Isolados-purple.svg)](#arquitetura)

---

## Visão Geral

O `template-agent` é o hub central de starters e protocolos de governança de engenharia para desenvolvimento colaborativo com agentes de IA (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider).

A estrutura resolve os quatro principais modos de falha em fluxos de trabalho autônomos e agentic:
- **Degradação de Contexto:** Carregamento com orçamento fixo de contexto (`AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`) elimina a saturação da janela em tarefas complexas.
- **Desvio de Contrato e Alucinação:** Definições de conclusão verificáveis (DoD), testes de caracterização e esquemas validáveis por máquina restringem as saídas do agente.
- **Refatoração Destrutiva:** Cercas de Chesterton (`INVARIANTS.md`) e restrições cirúrgicas de diff impedem refatorações não solicitadas em bases legadas.
- **Isolamento de Branches:** Os starters residem na raiz de branches git limpas e desacopladas, evitando monorepos inflados.

Playbooks transversais que abrangem múltiplos repositórios (contratos de UI, prototipagem HTML, auditoria de QA com navegador externo, padrões de documentação) são centralizados no catálogo organizacional de playbooks (`agent-skills`). Habilidades específicas e fluxos de onboarding permanecem integrados diretamente nas suas respectivas branches de template.

## Arquitetura

Os templates são isolados em raízes de branches dedicadas e independentes. Merges entre branches especializadas são estritamente proibidos; melhorias canônicas compartilhadas propagam-se exclusivamente via cherry-picks atômicos.

```mermaid
flowchart TD
    Main["main (Governança e Hub)"]
    Main -.->|"Sincronização seletiva / Cherry-pick"| Greenfield["greenfield (Projetos do Zero)"]
    Main -.->|"Sincronização seletiva / Cherry-pick"| Brownfield["brownfield (Adoção em Legados)"]
    Main -.->|"Sincronização seletiva / Cherry-pick"| Blackbox["blackbox (Engenharia Reversa)"]
    Main -.->|"Sincronização seletiva / Cherry-pick"| Infra["infra (Serviços e Homelab)"]
    Main -.->|"Sincronização seletiva / Cherry-pick"| Baremetal["baremetal (Workstation e Tuning)"]
```

### Matriz de Branches dos Starters

| Branch | Escopo Alvo | Artefatos Principais | Mecanismo Primário |
| :--- | :--- | :--- | :--- |
| **`greenfield`** | Projetos novos construídos do zero | `docs/adr/decisions.md`, `.agent/skills/`, `init.sh` | Raiz Git limpa, diário de decisões ADR, setup arquitetural aberto. |
| **`brownfield`** | Bases de código existentes e legados | `.agent/INVARIANTS.md`, `.agent/ECOSYSTEM.md`, `install.sh` | Injeção não destrutiva, cercas de Chesterton, Task 00 Discovery. |
| **`blackbox`** | Engenharia reversa e APIs fechadas | `.agent/ENDPOINTS.md`, `.agent/skills/reverse-engineering/`, `init.sh` | Catálogo de rotas descobertas, fixtures de replay, rate limits defensivos. |
| **`infra`** | Docker Compose, serviços e Homelab | `.agent/SERVICES.md`, `.agent/skills/compose-service/`, `compose.yaml.example` | Topologia de serviços, healthchecks estritos, limites de memória. |
| **`baremetal`** | Otimização de workstation e SO | `.agent/BASELINE.md`, `.agent/INVARIANTS.md`, `.agent/TUNINGS.md`, `init.sh` | Scripts rollback-first, inventário de sistema, proteção de kernel. |
| **`main`** | Governança do hub e matriz geral | `AGENTS.md`, `.agent/TASK.md`, `.github/workflows/ci.yml` | Documentação central, auditoria de deriva e roadmap do ecossistema. |

## Início Rápido

### Pré-requisitos

- Git 2.30+
- Bash 4.0+
- `curl` 7.60+

### 1. Criando um Projeto do Zero (Greenfield)

Inicialize um novo repositório limpo a partir do starter greenfield:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/greenfield/init.sh | bash -s -- meu-novo-projeto
cd meu-novo-projeto
```

*Alternativa via clone do Git:*
```bash
git clone --depth 1 -b greenfield https://github.com/ye-sandbox/template-agent.git meu-novo-projeto
cd meu-novo-projeto
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**Primeiro prompt para o agente:**
> "Leia AGENTS.md, .agent/TASK.md, .agent/NOTES.md e as skills em .agent/skills/. Apresente seu plano de implementação para a Tarefa Ativa do TASK.md antes de alterar qualquer código."

### 2. Adotando em um Projeto Existente (Brownfield)

Injete a estrutura de governança do agente diretamente na raiz do repositório existente:

```bash
# Execute a partir da raiz do repositório legado:
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash
```

*Execução não interativa:*
```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- -y
```

*Modo Stealth Corporativo (`--local-only`):*
```bash
# Impede que arquivos de governança de IA apareçam no git status ou no histórico compartilhado:
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- --local-only
```

**Primeiro prompt para o agente:**
> "Leia AGENTS.md e o .agent/TASK.md. Apresente seu plano de implementação para a Tarefa [00.1] Auditoria e Discovery do Projeto antes de alterar qualquer código."

### 3. Engenharia Reversa e Sistemas Fechados (Blackbox)

Inicialize um ambiente blackbox para descoberta de rotas, scrapers ou integrações com APIs fechadas:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/blackbox/init.sh | bash -s -- meu-projeto-blackbox
cd meu-projeto-blackbox
```

*Alternativa via clone do Git:*
```bash
git clone --depth 1 -b blackbox https://github.com/ye-sandbox/template-agent.git meu-projeto-blackbox
cd meu-projeto-blackbox
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**Primeiro prompt para o agente:**
> "Leia AGENTS.md, .agent/TASK.md, .agent/ENDPOINTS.md e a skill em .agent/skills/reverse-engineering/SKILL.md. Apresente seu plano para a Tarefa [00.1] Descoberta de Autenticação antes de executar requisições ativas."

### 4. Provisionando Infraestrutura e Serviços (Infra)

Inicialize um repositório para orquestração de serviços com Docker Compose e Homelab:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/infra/init.sh | bash -s -- meu-homelab
cd meu-homelab
```

*Alternativa via clone do Git:*
```bash
git clone --depth 1 -b infra https://github.com/ye-sandbox/template-agent.git meu-homelab
cd meu-homelab
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**Primeiro prompt para o agente:**
> "Leia AGENTS.md, .agent/SERVICES.md, .agent/TASK.md e a skill em .agent/skills/compose-service/SKILL.md. Apresente seu plano para a Tarefa [00.1] Provisionamento de Serviços Base antes de alterar arquivos de configuração."

### 5. Otimização de PC e Workstation (Baremetal)

Inicialize repositório de administração de host e tuning de SO com garantias de rollback:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/baremetal/init.sh | bash -s -- meu-workstation-ops
cd meu-workstation-ops
```

*Alternativa via clone do Git:*
```bash
git clone --depth 1 -b baremetal https://github.com/ye-sandbox/template-agent.git meu-workstation-ops
cd meu-workstation-ops
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

**Primeiro prompt para o agente:**
> "Leia AGENTS.md, .agent/BASELINE.md, .agent/INVARIANTS.md e a skill em .agent/skills/baremetal-tuning/SKILL.md. Apresente seu plano de implementação para a Tarefa [00.1] Auditoria de Baseline e Descoberta de Performance antes de executar modificações ou comandos privilegiados."

## Configuração

Variáveis de configuração definidas no `.env.example` e variáveis em nível de hub:

| Variável | Descrição | Padrão | Obrigatório |
| :--- | :--- | :--- | :--- |
| `APP_ENV` | Modo de ambiente de execução da aplicação (`development`, `production`, `test`) | `development` | Não |
| `APP_PORT` | Porta de escuta do servidor HTTP | `8000` | Não |
| `APP_SECRET_KEY` | Chave criptográfica para assinatura e cifragem de sessões | `change-me-in-production` | Sim (em produção) |
| `DATABASE_URL` | String de conexão PostgreSQL do banco de dados persistente principal | `postgresql://user:password@localhost:5432/dbname` | Não |
| `REDIS_URL` | String de conexão Redis para broker de fila, cache e mensageria | `redis://localhost:6379/0` | Não |
| `LLM_BASE_URL` | URL base do gateway LLM compatível com OpenAI v1 (Hydra LLM Router) | `http://hydra-llm-router:3000/v1` | Não |
| `LLM_API_KEY` | Token de autenticação do gateway correspondente ao tier alocado | `sk-replace-with-hydra-tier-token` | Sim (ao usar LLM) |
| `LLM_MODEL_FAST` | Alias do modelo virtual de baixa latência para classificação e parsing | `fast` | Não |
| `LLM_MODEL_DEEP` | Alias do modelo virtual para raciocínio profundo com orçamento de reasoning | `deep` | Não |
| `LLM_TIMEOUT_SECONDS` | Timeout do cliente HTTP em segundos para chamadas de reasoning | `180` | Não |
| `TEMPLATE_REPO_URL` | Sobrescrita de URL do repositório upstream para mirrors corporativos e forks | `https://github.com/ye-sandbox/template-agent.git` | Não |

A tabela apresenta os valores padrão de `main`. Cada starter mantém seu próprio `.env.example`; a auditoria de deriva compara os aliases com o contrato de roteamento da respectiva branch. `TEMPLATE_REPO_URL` é uma opção dos instaladores, não uma entrada no `.env.example` do hub.

## Matriz de Governança e Decisão

```mermaid
flowchart TD
    A{"Qual o cenário do projeto?"}
    A -->|"Projeto Novo do Zero"| B["branch greenfield"]
    B --> B1["Decisões registradas em ADRs formais"]
    B --> B2["Setup arquitetural e stack livre"]
    B --> B3["Skills de projeto em .agent/skills/"]

    A -->|"Código Legado Existente"| C["branch brownfield"]
    C --> C1["Sem ADRs retroativas; cercas em INVARIANTS.md"]
    C --> C2["Task 00 Discovery para mapear a stack"]
    C --> C3["Testes de caracterização obrigatórios antes de refatorar"]
    C --> C4["Diffs cirúrgicos com revisão de gate humana"]

    A -->|"Sistema Fechado / Sem Docs"| D["branch blackbox"]
    D --> D1["Catálogo de rotas em .agent/ENDPOINTS.md"]
    D --> D2["Playbook de engenharia reversa passo a passo"]
    D --> D3["Fixtures de replay e mocks antes do código final"]
    D --> D4["Taxas defensivas de requisição e proteção de tokens"]

    A -->|"Serviços / Homelab / IaC"| E["branch infra"]
    E --> E1["Topologia e portas em .agent/SERVICES.md"]
    E --> E2["Playbook padronizado compose-service"]
    E --> E3["Healthchecks e limites de memória obrigatórios"]
    E --> E4["Proteção contra exclusão destrutiva de volumes"]

    A -->|"SO Host / Otimização de PC"| F["branch baremetal"]
    F --> F1["Inventário do sistema em .agent/BASELINE.md"]
    F --> F2["Rollback-first: scripts de backup e reversão atômicos"]
    F --> F3["Modificações auditadas em .agent/TUNINGS.md"]
    F --> F4["Parâmetros de kernel e host protegidos por INVARIANTS.md"]
```

## Forks e Ambientes Corporativos

Para instâncias auto-hospedadas (GitHub Enterprise, GitLab, Gitea ou servidores Git barebone), os scripts `init.sh` e `install.sh` aceitam repositórios remotos personalizados via `TEMPLATE_REPO_URL`:

```bash
# Greenfield a partir de fork customizado
TEMPLATE_REPO_URL="https://github.com/SUA_ORGANIZACAO/template-agent.git" \
curl -fsSL https://raw.githubusercontent.com/SUA_ORGANIZACAO/template-agent/greenfield/init.sh | bash -s -- meu-novo-projeto

# Brownfield a partir de fork customizado
TEMPLATE_REPO_URL="https://raw.githubusercontent.com/SUA_ORGANIZACAO/template-agent/brownfield" \
curl -fsSL https://raw.githubusercontent.com/SUA_ORGANIZACAO/template-agent/brownfield/install.sh | bash

# Blackbox a partir de fork customizado
TEMPLATE_REPO_URL="https://github.com/SUA_ORGANIZACAO/template-agent.git" \
curl -fsSL https://raw.githubusercontent.com/SUA_ORGANIZACAO/template-agent/blackbox/init.sh | bash -s -- meu-projeto-blackbox

# Infra a partir de fork customizado
TEMPLATE_REPO_URL="https://github.com/SUA_ORGANIZACAO/template-agent.git" \
curl -fsSL https://raw.githubusercontent.com/SUA_ORGANIZACAO/template-agent/infra/init.sh | bash -s -- meu-homelab
```

### Sincronização de Forks com o Upstream

Mantenha seu fork atualizado preservando o isolamento estrito entre branches:

```bash
git remote add upstream https://github.com/ye-sandbox/template-agent.git
git fetch upstream

# Atualize cada branch isoladamente (nunca faça merge entre branches de starters diferentes):
git checkout main && git merge upstream/main
git checkout greenfield && git merge upstream/greenfield
git checkout brownfield && git merge upstream/brownfield
git checkout blackbox && git merge upstream/blackbox
git checkout infra && git merge upstream/infra
git checkout baremetal && git merge upstream/baremetal
```

## Desenvolvimento

### Estrutura do Projeto

```text
├── .agent/
│   ├── TASK.md               # Tarefa ativa, status de execução e log de roadmap
│   ├── NOTES.md              # Contratos arquiteturais e gotchas de runtime
│   ├── ARCHIVE.md            # Tarefas arquivadas de ciclos anteriores
│   ├── hooks/                # Hooks padronizados de ciclo de vida (post-worktree-create, pre-verify)
│   └── knowledge/            # Cards modulares de runtime e plataforma
├── .github/
│   ├── workflows/ci.yml      # Workflow de CI para matriz multibranch
│   └── scripts/              # Validação de drift, bootstrap fast-link, contratos e linter de LLM
├── docs/
│   ├── adr/decisions.md      # Registros consolidados de decisão arquitetural
│   ├── agent-sandbox.md      # Especificações de sandbox hermético via Bubblewrap e contêineres
│   ├── llm-gateway.md        # Integração com gateway OpenAI v1, modelos virtuais e isolamento de rede
│   ├── subagent-topology.md  # Papéis de subagentes em 3 tiers e contratos de delegação
│   └── worktree-isolation.md # Ciclo de vida de worktree, CLI fast-link e hooks de ciclo de vida
├── .env.example              # Esquema canônico de variáveis de ambiente
├── AGENTS.md                 # Constituição do repositório e regras de engenharia
├── CHANGELOG.md              # Notas de versão e histórico do ecossistema
├── README.md                 # Documentação em inglês
└── README.pt-br.md           # Documentação em português (Brasil)
```

### Verificação Adaptativa de Interfaces

Os cinco starters incluem a [skill interface-testing](.agent/skills/interface-testing/SKILL.md) e o [Invariante 7](.agent/INVARIANTS.md#7-adaptive-interface-verification--ui-protocol) compartilhado. A injeção Brownfield instala a skill nos modos padrão e stealth, preservando arquivos existentes quando nenhuma opção de sobrescrita é fornecida.

Carregue a skill apenas para tarefas de UI, preview ou componentes frontend. No T3 Code, o contrato cobre verificações de preview/device, localizadores de snapshots e encerramento das sessões. Em CLI/CI headless, use builds não bloqueantes, testes de componentes e E2E headless. Pesquisas de documentação estática usam ferramentas HTTP/busca.

A auditoria de deriva compara a skill byte a byte e compara somente o Invariante 7, preservando as demais restrições de cada starter. As asserções dos projetos gerados verificam a instalação da skill, das quatro restrições e das diretrizes de contexto/DoD para UI.

### Ferramentas de Governança do Ecossistema

As ferramentas de auditoria e migração do hub exigem Python 3. O auditor apresenta pontuações heurísticas de conformidade; ele não certifica o comportamento da aplicação. A migração trata da consolidação de ADRs, limpeza de NOTES, contratos de colaboração e diretrizes de governança. Examine as alterações propostas antes de aplicá-las.

```bash
python3 .github/scripts/audit-ecosystem-standards.py ~/github --format markdown --output /tmp/governance-audit.md
python3 .github/scripts/apply-governance-standards.py ~/github --dry-run
```

### Comandos de Validação

```bash
# Validar contratos de governança e deriva de arquivos entre as branches
.github/scripts/check-branch-drift.sh

# Testar a detecção de deriva em refs Git locais descartáveis
bash .github/scripts/test-branch-drift.sh

# Validar definições de micro-contrato e guardrails de isolamento por worktree
.github/scripts/verify-microcontract.sh

# Auditar segurança de comandos e guardrails de raio de explosão
.github/scripts/audit-command-security.sh

# Bootstrap fast-link de dependências (.venv, node_modules) e hooks de ciclo de vida
.github/scripts/bootstrap-worktree.sh --self-test

# Validar contratos do LLM gateway, isolamento de rede e roteamento de modelos virtuais
.github/scripts/verify-llm-contract.sh self-test

# Validar auditoria e migração do ecossistema com fixtures herméticas
python3 .github/scripts/audit-ecosystem-standards.py --self-test
python3 .github/scripts/apply-governance-standards.py --self-test
python3 .github/scripts/audit-ecosystem-standards.py . --no-exclude --fail-under 90

# Executar suíte de testes de ponta a ponta dos starters
.github/scripts/test-all-starters.sh

# Verificar integridade de formatação e espaços em branco
git diff --check
```

## Licença

Distribuído sob a licença [MIT](https://opensource.org/license/mit).
