# Habilidades do Projeto (`.agent/skills/`)

Este diretório armazena as **Habilidades Especializadas (Skills)** do repositório. Enquanto o `AGENTS.md` define as **regras e restrições** ("o que fazer e não fazer") e o `NOTES.md` guarda as **decisões e contexto** ("o porquê"), as **Skills** ensinam o agente **como executar fluxos procedurais complexos com precisão**.

---

## 🧭 O Papel de Cada Componente

| Arquivo / Diretório | Função Principal | Pergunta Respondida |
| :--- | :--- | :--- |
| **`AGENTS.md`** | Constituição do projeto, DoD, stack e regras inegociáveis | *Quais são as regras e limites?* |
| **`.agent/TASK.md`** | Escopo da tarefa ativa e backlog imediato | *O que deve ser feito agora?* |
| **`.agent/NOTES.md`** | Decisões técnicas rápidas, armadilhas e contratos | *Por que foi feito assim?* |
| **`.agent/adr/`** | Decisões arquiteturais formais e complexas | *Quais alternativas foram ponderadas?* |
| **`.agent/skills/`** | Manuais operacionais passo a passo de procedimentos | *Como executar este fluxo com maestria?* |

---

## 📁 Estrutura de uma Skill

Cada habilidade deve residir em sua própria subpasta contendo um arquivo `SKILL.md`:

```text
.agent/skills/
├── README.md                  # Este guia
├── 000-template.md            # Template canônico para criar novas skills
├── [nome-da-skill]/
│   ├── SKILL.md               # Instruções operacionais detalhadas
│   ├── examples/              # (Opcional) Exemplos de entrada e saída
│   └── scripts/               # (Opcional) Scripts auxiliares ou de validação
```

O arquivo `SKILL.md` deve iniciar com cabeçalho YAML padronizado:

```yaml
---
name: nome-da-skill
description: Resumo conciso de uma linha sobre o que esta skill ensina e quando ativá-la.
---
```

---

## 🎯 Quando Criar uma Skill no Projeto?

### ✅ Crie uma Skill quando:
- Houver um **fluxo repetitivo de mais de 3 passos** no projeto (ex: criar uma nova entidade com rota, service, migration e testes).
- Houver um **padrão de integração específico** com um serviço ou biblioteca (ex: formato padrão de eventos para filas, schemas de payload padronizados).
- Houver um procedimento de **debug ou validação especializado** (ex: como validar queries pesadas, como reproduzir fluxos assíncronos locais).
- Houver ferramentas auxiliares ou servidores MCP específicos que exigem sequência correta de chamadas.

### ❌ NÃO crie uma Skill quando:
- For uma regra geral de código ou estilo (use `AGENTS.md`).
- For uma decisão arquitetural pontual ou registro de débito técnico (use `.agent/NOTES.md`).
- For uma ferramenta de infraestrutura geral do seu ambiente/homelab que se aplica a múltiplos repositórios (ex: consulta geral ao VictoriaLogs, controle de containers Proxmox). Nesses casos, prefira **Skills Globais** configuradas no ambiente da sua máquina/IDE.

---

## 🚀 Como Criar uma Nova Skill

1. Copie o arquivo [`000-template.md`](./000-template.md) para uma nova pasta com o nome da habilidade:
   ```bash
   mkdir -p .agent/skills/minha-skill
   cp .agent/skills/000-template.md .agent/skills/minha-skill/SKILL.md
   ```
2. Preencha as seções com instruções imperativas, exemplos de código reais e possíveis armadilhas.
3. Se aplicável, adicione uma menção à nova skill no `AGENTS.md` na seção de Habilidades Especializadas.
