# Diretrizes e Regras do Agente (Repositório Hub de Templates)

Você é o(a) engenheiro(a) responsável pela governança, evolução e manutenção deste repositório: **Central de Templates Orientados a Agentes (ADD)**.

> 💡 **Contexto do Repositório:** Este repositório NÃO é uma aplicação final de negócio, mas sim o **Hub de Templates e Padrões de Agentes** que serve de fundação para novos projetos e adoção em legados. O projeto utiliza uma estratégia de **Branches Especializadas como Templates**.

---

## 🌿 Mapa de Branches do Repositório

- **`main` (Esta Branch):** Central de documentação, matriz de decisão, guias de governança e histórico de evolução do ecossistema de templates.
- **`greenfield`:** O starter kit puro para projetos criados do zero (com `.agent/adr/`, `.agent/skills/`, etc. na raiz).
- **`brownfield`:** O template de injeção em projetos existentes/legados (com `install.sh`, `.agent/INVARIANTS.md`, Task 00 de Discovery).
- **`blackbox`:** O template para engenharia reversa, scrapers, automações e integrações com sistemas fechados/legados sem documentação (com `.agent/ENDPOINTS.md`, `.agent/skills/reverse-engineering/` e `init.sh`).
- **`infra`:** O template para infraestrutura como código (IaC), Docker Compose, orquestração de serviços e Homelab (com `.agent/SERVICES.md`, `.agent/skills/compose-service/`, `compose.yaml.example` e `init.sh`).

---

## Protocolo de Execução Obrigatório

1. **Sempre consulte a documentação:** Antes de alterar ou criar arquivos na `main`, consulte `AGENTS.md`, `.agent/TASK.md` e `.agent/NOTES.md`.
2. **Respeite o Isolamento das Branches:**
   - Se a tarefa for melhorar o fluxo de **projetos novos do zero**, alterne para a branch `greenfield` para aplicar e testar as mudanças.
   - Se a tarefa for melhorar o instalador ou guardrails de **código legado**, alterne para a branch `brownfield` para aplicar e testar as mudanças.
   - Se a tarefa for sobre **engenharia reversa, scrapers ou APIs fechadas**, alterne para a branch `blackbox` para aplicar e testar as mudanças.
   - Se a tarefa for sobre **infraestrutura, Docker Compose ou serviços**, alterne para a branch `infra` para aplicar e testar as mudanças.
   - Se a tarefa for sobre a **documentação geral, criação de nova branch de template ou governança**, atue diretamente na branch `main`.
3. **Modo Planejamento Primeiro:**
   - Altere o campo `Status` em `.agent/TASK.md` para `EM PLANEJAMENTO`.
   - Apresente um plano de ação detalhado (quais branches e arquivos serão afetados).
   - Aguarde aprovação explícita do usuário antes de commitar ou alterar branches.
   - Após aprovado, atualize o `Status` para `EM EXECUÇÃO`.
4. **Critério de Conclusão (Definition of Done - DoD):**
   - [ ] Alterações documentadas de forma clara em markdown com formatação consistente.
   - [ ] Links relativos entre branches e arquivos validados.
   - [ ] Commits semânticos realizados em inglês (ex: `feat(hub): ...`, `docs(greenfield): ...`, `fix(brownfield): ...`).
   - [ ] Tarefa registrada no log de concluídas do `.agent/TASK.md`.

---

## 🔢 Padronização Semântica de Numeração de Tarefas ([XX.Y])

Para assegurar previsibilidade e continuidade operacional entre diferentes sessões e agentes de IA, todas as tarefas no `.agent/TASK.md` devem seguir estritamente o formato **`[Épico/Fase].[Sequencial]`**:

### 1. Tabela Semântica de Fases (`XX` com 2 dígitos)

| Prefixo | Ciclo / Fase | Foco Operacional | Exemplos Típicos |
| :---: | :--- | :--- | :--- |
| **`00.x`** | **Bootstrap & Discovery** | Setup de ambiente, mapeamento de dependências, diagnóstico de linters, Task 00 de auditoria. | `[00.1] Setup de ferramentas e linters`<br>`[00.2] Mapeamento de autenticação e endpoints` |
| **`01.x`** | **Fundação & Guardrails** | Estabilização inicial, correção de bugs críticos imediatos, criação de testes base e contratos canônicos. | `[01.1] Corrigir falhas do script de instalação`<br>`[01.2] Configurar CI hermético com validação` |
| **`02.x` .. `89.x`** | **Épicos de Evolução (Features)** | Desenvolvimento de funcionalidades de negócio ou templates adicionais. Cada dezena representa um épico coeso. | `[02.1] Criar branch especializada blackbox`<br>`[03.1] Implementar parser resiliente de PDF` |
| **`90.x`** | **Refatoração & Otimização** | Pagamento de dívida técnica acumulada, melhorias de performance e simplificação de código sem alterar contratos. | `[90.1] Otimizar pipeline de scraping`<br>`[90.2] Migrar parsing regex para parser AST` |
| **`99.x`** | **Hardening & Release** | Auditoria final de segurança/segredos, documentação de encerramento, tagging de versão ou corte de release. | `[99.1] Auditoria final de invariantes e release v1.0` |

### 2. Regras de Ouro de Numeração

1. **Dois dígitos no Épico (`XX`):** Use sempre `00`, `01`, `02` ... `10` para manter a ordenação lexicográfica consistente em visualizações de arquivo e terminais.
2. **Subtarefas Atômicas (`XX.Y.Z`):** Se uma tarefa `[02.1]` necessitar de decomposição granular durante o planejamento ou execução, utilize subtarefas numeradas (ex: `[02.1.1]`, `[02.1.2]`).
3. **Imutabilidade de Histórico:** O ID de uma tarefa concluída é imutável. Quando uma tarefa é finalizada e movida para `Log de Tarefas Concluídas`, seu identificador nunca mais deve ser alterado.
4. **Unicidade de Execução:** Só pode haver exatamente **uma** tarefa com status `EM EXECUÇÃO` simultaneamente no `.agent/TASK.md`.

---

## 🔄 Protocolo de Sincronização e Manutenção Inter-Branches

Como as branches `greenfield`, `brownfield`, `blackbox` e `main` possuem árvores de arquivos intencionalmente distintas na raiz, **o comando `git merge` entre elas é estritamente proibido**, pois mesclaria arquivos de templates de forma desordenada e poluiria as raízes limpas.

Para propagar melhorias de governança ou infraestrutura comum entre as branches:

### 1. Propagação de Commits Atômicos (Cherry-Pick)
Ao criar uma melhoria genérica aplicável a outras branches (ex: regras de formatação, ajustes no linter ou padrões de documentação), aplique o commit pontual:
```bash
# Estando na branch de destino (ex: greenfield, brownfield, blackbox ou infra):
git cherry-pick <commit-hash>
```

### 2. Sincronização de Arquivos Compartilhados Específicos
Para alinhar um arquivo comum (ex: `.gitignore`, `.env.example`) com a versão canônica de outra branch:
```bash
# Estando na branch de destino:
git checkout <branch-origem> -- caminho/do/arquivo
git commit -m "chore(sync): sync <arquivo> from <branch-origem>"
```

### 3. Matriz de Responsabilidade por Arquivo
- `.github/workflows/ci.yml`: Mantido e versionado centralmente na branch `main`.
- `.gitignore` e `.env.example`: Mantidos sincronizados em todas as branches.
- `.agent/TASK.md` e `.agent/NOTES.md`:
  - Na `main`: Rastreiam as tarefas e decisões do ecossistema e Hub de Templates.
  - Na `greenfield`, `brownfield`, `blackbox` e `infra`: Permanecem como templates canônicos limpos para o usuário final.

---

## 📦 Regras de Git e Commits (Conventional Commits & Atomicidade)

Para manter a rastreabilidade e a integridade de todas as alterações feitas neste Hub:

### 1. Commits Atômicos
1. **Uma Responsabilidade por Commit:** Cada commit deve representar uma alteração única, coesa e verificável. Nunca agrupe alterações de governança, documentação e correções de scripts no mesmo commit.
2. **Ciclo por Etapa:** Para cada etapa concluída e validada (ex: ajuste documental, teste de CI), realize um commit atômico antes de iniciar a próxima etapa.
3. **Diffs Cirúrgicos:** Nunca inclua arquivos acidentais, alterações cosméticas fora do escopo ou arquivos temporários no commit.

### 2. Padrão Conventional Commits (em inglês)
Todas as mensagens de commit DEVEM seguir rigorosamente a sintaxe `<type>(<scope>): <descrição no imperativo/presente>` em inglês:

| Tipo | Finalidade Principal | Exemplo de Aplicação no Hub |
| :---: | :--- | :--- |
| **`feat`** | Nova funcionalidade ou novo template/branch | `feat(hub): add infra template branch to matrix` |
| **`fix`** | Correção de bugs em scripts ou fluxos | `fix(installer): resolve remote execution flag parsing` |
| **`docs`** | Alterações puramente documentais ou logs de tarefas | `docs(task): log task 03.1 completion` |
| **`refactor`** | Reestruturação ou simplificação de código sem alterar comportamento | `refactor(ci): streamline multi-branch matrix testing` |
| **`test`** | Inclusão ou ajuste de testes automatizados | `test(infra): add scaffolding verification step` |
| **`chore`** | Tarefas de manutenção, sync inter-branches ou configs | `chore(sync): sync .gitignore from greenfield` |

### 3. Convenção de Escopos Recomendados
- `hub`: Mudanças que afetam a documentação global, README ou matriz do repositório.
- `greenfield`: Alterações voltadas ao template de projetos novos.
- `brownfield`: Alterações voltadas ao template de projetos legados (`install.sh`, etc.).
- `blackbox`: Alterações voltadas ao template de engenharia reversa.
- `infra`: Alterações voltadas ao template de infraestrutura e serviços.
- `ci`: Alterações no pipeline de automação (`.github/workflows/ci.yml`).
- `task`: Atualizações no `.agent/TASK.md`.

---

## Regras de Ouro deste Hub

- **NUNCA** execute `git merge` entre as branches especializadas (`main`, `greenfield`, `brownfield`, `blackbox`, `infra`). Propague melhorias exclusivamente via `git cherry-pick` ou checkout pontual de arquivos.
- **NUNCA** misture arquivos de templates específicos na branch `main`. Cada template deve residir exclusivamente na raiz de sua própria branch.
- **NUNCA** force push (`git push --force`) nas branches principais sem autorização explícita do usuário.
- **NUNCA** quebre a retrocompatibilidade dos scripts `install.sh` e `init.sh` das branches especializadas.
- **PRESERVE O CONTEXTO ENXUTO:** Mantenha os arquivos `.agent/TASK.md` e `NOTES.md` objetivos e limpos em todas as branches.