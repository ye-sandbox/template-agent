# Template de Infraestrutura, Serviços & Homelab (ADD)

Este repositório é a fundação para gerenciamento, orquestração e evolução de **serviços de infraestrutura e Homelab orientados a agentes de IA** (Docker Compose, VictoriaLogs, Uptime Kuma, bancos de dados, proxies reversos e observabilidade).

A estrutura foi projetada para eliminar os riscos comuns de agentes atuando em infraestrutura: **colisão de portas**, **perda acidental de volumes**, **vazamento de credenciais em YAML** e **ausência de limites de recursos**.

---

## 🏛️ Estrutura do Template

```text
├── .agent/
│   ├── ARCHIVE.md               # Histórico de tarefas arquivadas
│   ├── NOTES.md                 # Decisões de infraestrutura e invariantes técnicas
│   ├── SERVICES.md              # Fonte canônica viva: Portas, Volumes, Redes e Healthchecks
│   ├── TASK.md                  # Tarefa ativa e roadmap de evolução dos serviços
│   └── skills/
│       ├── 000-template.md      # Template para novos procedimentos operacionais
│       ├── README.md            # Catálogo de skills de infraestrutura
│       └── compose-service/     # Procedimento padronizado para adicionar/alterar serviços
├── compose.yaml.example         # Exemplo canônico de compose com healthchecks e limits
├── .env.example                 # Contrato de variáveis de ambiente e portas
├── .gitignore                   # Proteção contra commit de dados, volumes e segredos
├── AGENTS.md                    # Regras de ouro de SRE/DevOps e guardrails inegociáveis
└── README.md                    # Documentação do projeto
```

---

## 🚀 Como Inicializar e Usar

### 1. Criar o arquivo de ambiente e configurar variáveis
```bash
cp .env.example .env
# Ajuste as portas e credenciais conforme o host
```

### 2. Inicializar o arquivo de serviços a partir do exemplo
```bash
cp compose.yaml.example compose.yaml
```

### 3. Validar a sintaxe do Compose
```bash
docker compose config --quiet && echo "Compose sintaticamente válido!"
```

### 4. Subir os serviços em background
```bash
docker compose up -d
docker compose ps
```

---

## 🤖 Primeiro Prompt para o Agente de IA

Ao abrir este repositório no seu editor com agente (Cursor, Windsurf, Antigravity, Roo Code):

> *"Leia o AGENTS.md, .agent/SERVICES.md, .agent/TASK.md e a skill em .agent/skills/compose-service/SKILL.md. Apresente seu plano de implementação para a Tarefa [00.1] antes de alterar qualquer arquivo de configuração."*
