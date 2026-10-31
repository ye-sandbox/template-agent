# Brownfield Starter Kit

Framework de governança técnica para introduzir agentes de IA com segurança em projetos legados e existentes.

**[English](README.md)** | **[Português (Brasil)](README.pt-br.md)**

[![CI](https://github.com/ye-sandbox/template-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/ye-sandbox/template-agent/actions)
[![Starter: Brownfield](https://img.shields.io/badge/Starter-Brownfield-amber.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Visão Geral

O starter kit Brownfield fornece uma estrutura de governança controlada para introduzir agentes de codificação por IA (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider) em bases de código existentes e em produção, sem o risco de introduzir regressões silenciosas ou violar contratos implícitos do sistema.

Diferente de projetos Greenfield onde os agentes desenham arquiteturas livremente, projetos legados operam sob restrições estritas:
- **Injeção Não Destrutiva:** O template injeta a governança no repositório existente sem tocar em código fonte ou arquivos de manifesto de dependências.
- **Cercas de Chesterton:** Comportamentos intocáveis, dependências congeladas e idiossincrasias justificadas são documentados em `.agent/INVARIANTS.md`.
- **Modo Stealth Corporativo:** A flag `--local-only` registra toda a configuração no `.git/info/exclude`, mantendo o `.gitignore` inalterado e o `git status` 100% limpo.
- **Task 00 Discovery:** Protocolo inicial obrigatório que mapeia entrypoints, gerenciadores de pacotes e suítes de teste no `AGENTS.md` antes de qualquer alteração de código.

## Arquitetura

```mermaid
flowchart TD
    Inject["install.sh (Injeção de Governança)"] --> Task00["Task 00 Discovery e Auditoria"]
    Task00 --> Calibrate["Calibrar AGENTS.md e INVARIANTS.md"]
    Calibrate --> Task["Tarefa Ativa no TASK.md"]
    Task --> Characterize["Testes de Caracterização (Comprovar Comportamento)"]
    Characterize --> Plan["Plano de Implementação do Agente"]
    Plan --> Gate{"Gate de Revisão Humana"}
    Gate -->|"Aprovado"| Code["Implementação com Diff Cirúrgico"]
    Gate -->|"Ajustes Solicitados"| Plan
    Code --> Verify["Validação (Suítes Existentes + DoD)"]
    Verify --> Commit["Commit Atômico (Local / Gate Humano de Push)"]
```

### Estrutura de Diretórios Injetada

```text
├── AGENTS.md                 # Constituição para código legado (regras de não-regressão e escopo)
├── install.sh                # Script de injeção em repositórios existentes
├── docs/adr/decisions.md     # Registros de Decisões de Arquitetura (log de ADRs)
└── .agent/
    ├── TASK.md               # Tarefa ativa (iniciada com Task 00 Discovery)
    ├── INVARIANTS.md         # Comportamentos intocáveis, dependências congeladas e bizarrices
    ├── NOTES.md              # Contratos vigentes mapeados, entrypoints e armadilhas
    ├── ARCHIVE.md            # Histórico de tarefas concluídas
    ├── ECOSYSTEM.md          # Topologia multi-repo, contratos entre serviços e limites
    └── knowledge/            # Cards modulares de gotchas e armadilhas de runtime
        ├── 000-schema.md     # Especificação do schema de knowledge cards
        └── k-000-template.md # Template para novos knowledge cards
```

## Início Rápido

### Pré-requisitos

- Git 2.30+
- Bash 4.0+
- `curl` 7.60+

### Injetando em um Repositório Existente

Execute o instalador diretamente a partir da raiz do seu projeto existente:

```bash
# Injeção automatizada padrão
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash
```

```bash
# Injeção não interativa (para pipelines de CI ou setup automatizado)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- -y
```

```bash
# Modo Stealth Corporativo (local-only, oculta toda a governança do git status)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- --local-only
```

*Alternativa via execução local do script:*

```bash
./install.sh /caminho/para/projeto-existente
# ou com modo stealth corporativo:
./install.sh --local-only /caminho/para/projeto-existente
```

### Prompt Inicial de Discovery

Envie este prompt ao seu agente de IA logo após a injeção da estrutura:

> "Leia AGENTS.md e o .agent/TASK.md. Apresente seu plano de implementação para a Tarefa [00.1] Auditoria e Discovery do Projeto antes de alterar qualquer código."

## Configuração

O template fornece esquemas de configuração padronizados através do `.env.example`:

| Variável | Descrição | Padrão | Obrigatório |
| :--- | :--- | :--- | :--- |
| `APP_ENV` | Modo de ambiente de execução da aplicação (`development`, `production`, `test`) | `development` | Não |
| `APP_PORT` | Porta de escuta do servidor HTTP | `8000` | Não |
| `APP_SECRET_KEY` | Chave criptográfica para assinatura e cifragem de sessões | `change-me-in-production` | Sim (em produção) |
| `DATABASE_URL` | String de conexão PostgreSQL do banco de dados persistente principal | `postgresql://user:password@localhost:5432/dbname` | Não |
| `REDIS_URL` | String de conexão Redis para broker de fila, cache e mensageria | `redis://localhost:6379/0` | Não |

## Uso

### Regras Fundamentais Brownfield

1. **Testes de Caracterização Primeiro:** Ao modificar funções legadas sem cobertura de testes, escreva primeiro um teste que comprove o comportamento atual antes de tocar na lógica da aplicação.
2. **Sem Refatoração Oportunista:** Mantenha os diffs cirúrgicos. Nunca reformate arquivos intocados, não altere estilos adjacentes nem execute limpezas fora do escopo.
3. **Gate Obrigatório de Revisão Humana:** Em repositórios legados de produção, pushes autônomos para remotos compartilhados são proibidos. Todos os commits exigem validação humana.
4. **Respeitar Invariantes:** Consulte `.agent/INVARIANTS.md` antes de alterar qualquer código que pareça redundante ou subótimo à primeira vista.

## Desenvolvimento

### Comandos de Validação

```bash
# Verificar integridade de formatação e espaços em branco
git diff --check
```

## Licença

Distribuído sob a licença [MIT](LICENSE).
