# Template Brownfield para Desenvolvimento Orientado a Agentes (ADD)

> 🧱 **Focado em Código Legado e Projetos Já Existentes.**
> Uma estrutura projetada para introduzir agentes de Inteligência Artificial (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider, etc.) em repositórios com código existente, sem correr o risco de quebrar contratos implícitos ou causar regressões silenciosas.

---

## 💡 Por que um template específico para Legados?

Trabalhar com IA em projetos novos (Greenfield) é muito diferente de trabalhar em código legado (Brownfield):
- **No Greenfield:** O agente projeta arquitetura do zero, cria ADRs e define contratos livres.
- **No Brownfield:** Decisões já foram tomadas. O agente precisa agir com cautela cirúrgica (*Princípio de Chesterton*), escrever **testes de caracterização** antes de refatorar e respeitar contratos de sistemas legados.

---

## 📁 Estrutura do Template

```text
├── AGENTS.md                 # A "Constituição" para código legado (regras de não-regressão e escopo cirúrgico)
├── install.sh                # Script para injetar este template em qualquer repositório existente
└── .agent/
    ├── TASK.md               # Tarefa ativa (iniciando com o Protocolo de Discovery)
    ├── INVARIANTS.md         # Comportamentos intocáveis, dependências congeladas e bizarrices justificadas
    ├── NOTES.md              # Contratos vigentes mapeados e armadilhas recentes
    └── ARCHIVE.md            # Histórico de tarefas antigas para manter contexto enxuto
```

---

## 🚀 Como Injetar este Template em um Repositório Legado

### Opção 1: Via Script Automático (Recomendado)

Estando na raiz do seu projeto legado existente, execute o instalador one-liner via `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash
```

> 💡 **Dica para automações ou CI:** Passe a flag `-y` para não solicitar confirmações interativas:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- -y
> ```
> Para instalar em um diretório específico:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- ./caminho/do/projeto
> ```

Ou, caso tenha clonado a branch `brownfield` localmente:
```bash
./install.sh /caminho/para/seu-projeto-legado
```

### Opção 2: Cópia Manual
Copie o arquivo `AGENTS.md` e a pasta `.agent/` diretamente para a raiz do seu projeto existente.

---

## 🔄 O Ciclo de Adoção: Task 00 (Discovery)

Assim que os arquivos forem copiados para o seu projeto legado:

1. Abra seu editor com o agente de IA na raiz do projeto.
2. Envie o prompt inicial:
   > *"Leia o AGENTS.md e o .agent/TASK.md. Apresente seu plano de implementação para a Tarefa [00.1] de Auditoria e Discovery antes de alterar qualquer código."*
3. O agente irá:
   - Identificar linguagens, versões e gerenciador de pacotes nos arquivos de build (`package.json`, `pyproject.toml`, etc.).
   - Preencher os comandos de teste, lint e run reais no `AGENTS.md`.
   - Mapear pontos de entrada e variáveis de ambiente.
   - Registrar as primeiras regras críticas em `.agent/INVARIANTS.md`.
4. Uma vez concluído o Discovery, seu projeto estará 100% calibrado para receber novas tarefas, bugfixes e refatorações com segurança!

---

## 🛡️ Regras Fundamentais deste Template

1. **Testes de Caracterização:** Se uma função legada não tem testes e precisa ser alterada, o agente deve primeiro escrever um teste que comprove o comportamento atual antes de modificar a lógica.
2. **Sem Refatoração Oportunista:** Diffs devem ser cirúrgicos. Proibido reformatar arquivos inteiros ou mudar estilo fora do escopo da tarefa.
3. **Invariantes Respeitadas:** Decisões que parecem ruins ou redundantes devem ser verificadas no `INVARIANTS.md` antes de qualquer alteração.
