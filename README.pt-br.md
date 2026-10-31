# Greenfield Starter Kit

Base técnica para desenvolvimento de software do zero com agentes de IA.

**[English](README.md)** | **[Português (Brasil)](README.pt-br.md)**

[![CI](https://github.com/ye-sandbox/template-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/ye-sandbox/template-agent/actions)
[![Starter: Greenfield](https://img.shields.io/badge/Starter-Greenfield-success.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Visão Geral

O starter kit Greenfield fornece uma base limpa para criação de novas aplicações, microsserviços e bibliotecas utilizando agentes de codificação por IA (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider). Projetos Greenfield iniciam com setup arquitetural livre, governado por Registros de Decisões de Arquitetura (ADRs) e gates estritos de Definition of Done (DoD).

O starter resolve os principais modos de falha no desenvolvimento orientado a agentes:
- **Preservação de Contexto:** Carregamento com orçamento fixo de contexto (`AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`), arquivando tarefas concluídas em `.agent/ARCHIVE.md`.
- **Rastreabilidade Arquitetural:** Preserva decisões duradouras em `docs/adr/decisions.md`, mantendo as notas operacionais ativas enxutas.
- **Extensibilidade Modular:** Suporta procedimentos especializados em `.agent/skills/` e captura de armadilhas de execução em `.agent/knowledge/`.
- **Scaffolding Automatizado:** Provisiona repositório Git limpo e documentação inicial do produto via `init.sh` em um único comando.

## Arquitetura

```mermaid
flowchart TD
    Task["TASK.md (Tarefa Ativa)"] --> Plan["Plano de Implementação do Agente"]
    Plan --> Review{"Aprovação Humana"}
    Review -->|"Aprovado"| Running["Status: RUNNING"]
    Review -->|"Ajustes Solicitados"| Plan
    Running --> Code["Implementação e Testes"]
    Code --> DoD["Definition of Done (100% dos Testes Passam)"]
    DoD --> Commit["Conventional Commit em Inglês"]
    Commit --> Done["Registra em Concluídas e Promove Próxima"]
```

### Estrutura de Diretórios

```text
├── AGENTS.md                 # Constituição do projeto (regras, stack, MCPs, validações)
├── .agent/
│   ├── TASK.md               # Tarefa ativa, critérios de aceite e roadmap imediato
│   ├── NOTES.md              # Decisões rápidas de arquitetura, contratos e gotchas
│   ├── ARCHIVE.md            # Histórico de tarefas concluídas
│   ├── ECOSYSTEM.md          # Topologia multi-repo e limites entre serviços (opcional)
│   ├── knowledge/            # Cards modulares de gotchas e armadilhas de runtime
│   │   ├── 000-schema.md     # Especificação do schema de knowledge cards
│   │   └── k-000-template.md # Template para novos knowledge cards
│   └── skills/               # Habilidades procedurais especializadas do projeto
│       ├── README.md         # Guia de criação e uso de skills
│       └── 000-template.md   # Template padrão de SKILL.md
├── docs/
│   └── adr/
│       └── decisions.md      # Registros consolidados de Decisões Arquiteturais (ADRs)
├── .env.example              # Contrato canônico de variáveis de ambiente
├── .gitignore                # Padrões abrangentes (Node, Python, Docker, caches de agentes)
├── init.sh                   # Script de scaffolding para novos repositórios
└── README.md                 # Documentação do starter
```

## Início Rápido

### Pré-requisitos

- Git 2.30+
- Bash 4.0+
- `curl` 7.60+

### Criando um Novo Projeto

Execute o script de inicialização diretamente no seu terminal:

```bash
# Scaffolding padrão (inclui ECOSYSTEM.md multi-repo)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/greenfield/init.sh | bash -s -- meu-novo-projeto
cd meu-novo-projeto
```

```bash
# Modo standalone (omite ECOSYSTEM.md multi-repo)
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/greenfield/init.sh | bash -s -- --standalone meu-novo-projeto
cd meu-novo-projeto
```

*Alternativa via clone manual do Git:*

```bash
git clone --depth 1 -b greenfield https://github.com/ye-sandbox/template-agent.git meu-novo-projeto
cd meu-novo-projeto
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial setup"
```

### Prompt Inicial

Envie este prompt ao seu agente de codificação no primeiro turno:

> "Leia AGENTS.md, .agent/TASK.md, .agent/NOTES.md e as skills em .agent/skills/. Apresente seu plano de implementação para a Tarefa Ativa do TASK.md antes de alterar qualquer código."

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

### Protocolo de Ciclo de Vida da Tarefa

1. **Definição da Tarefa:** Especifique o objetivo em `Active Task` no `.agent/TASK.md` com critérios claros de aceite.
2. **Revisão Plan-First:** O agente define o status como `PLANNING` e apresenta um plano de implementação. Aguarde aprovação humana antes de alterar código.
3. **Execução e Validação:** Atualize o status para `RUNNING`. Execute a implementação executando validações até 100% de sucesso.
4. **Conclusão:** Faça o commit com Conventional Commit atômico (`feat(...)`, `fix(...)`), registre a conclusão no log do `.agent/TASK.md` e promova a próxima tarefa.

## Desenvolvimento

### Comandos de Validação

```bash
# Verificar integridade de formatação e espaços em branco
git diff --check

# Executar suíte de testes locais do projeto (configurar no AGENTS.md na Task 00.1)
npm test
```

## Licença

Distribuído sob a licença [MIT](LICENSE).
