# Catálogo de Procedimentos Operacionais (Skills de Infraestrutura)

Este diretório contém os procedimentos passo a passo que ensinam aos agentes de IA como operar e evoluir a infraestrutura de forma segura e padronizada.

---

## Skills Ativas

| Skill | Localização | Propósito Principal |
| :--- | :--- | :--- |
| **`compose-service`** | [`compose-service/SKILL.md`](./compose-service/SKILL.md) | Adicionar ou atualizar serviços no Docker Compose garantindo portas, volumes, healthcheck e limites de recursos. |

---

## Como Criar uma Nova Skill de Infraestrutura

1. Copie o arquivo modelo [`000-template.md`](./000-template.md) para uma nova pasta `.agent/skills/<nome-da-skill>/SKILL.md`.
2. Preencha o frontmatter YAML (`name` e `description`).
3. Detalhe pré-requisitos, etapas de execução e validação.
4. Adicione a nova skill à tabela acima e ao catálogo no `AGENTS.md`.
