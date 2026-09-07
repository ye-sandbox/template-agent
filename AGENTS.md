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

## Numeração de Tarefas (`[XX.Y]`)

Formato `[Épico].[Sequencial]` com épico de **dois dígitos**. Subtarefas: `[XX.Y.Z]`. Só **uma** tarefa `EM EXECUÇÃO`. IDs imutáveis dentro da release. Após tag Git: arquivar no `ARCHIVE.md`, reiniciar em `[00.1]`/`[01.1]` e corrigir o ID da tarefa ativa.

**Próximo ID:** só Tarefa Ativa + Log do ciclo vigente. Ignore Backlog Futuro e a seção de encerramento. Mesmo épico → `Y+1` (`[04.4]` → `[04.5]`). Épico novo → `[XX+1.1]`. Não salte para `90.x`/`99.x` a menos que o trabalho seja refatoração/release **e** o usuário peça.

**Release:** `[99.1]` não é item de fila. Só vira Tarefa Ativa com permissão explícita. Nunca inicie tag/higiene de release sozinho; nunca use `99.x` como teto.

| Prefixo | Fase | Foco neste hub |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Discovery | Setup, linters, auditoria inicial |
| **`01.x`** | Fundação & Guardrails | Bugs críticos, CI, contratos canônicos |
| **`02.x`–`89.x`** | Épicos | Novos templates, features do hub (cada dezena = um épico) |
| **`90.x`** | Refatoração | Dívida técnica sem mudar contratos |
| **`99.x`** | Hardening & Release | Auditoria final e tag — só com permissão humana |

---

## Higiene Pós-Release (gatilho: tag Git, qualquer fase)

Não está preso à fase `99.x`. Ao publicar `vX.Y.Z`:

1. **Arquivar:** mover o log do ciclo de `TASK.md` → `ARCHIVE.md` sob `## [vX.Y.Z] - AAAA-MM-DD`.
2. **Consolidar:** promover decisões definitivas para ADRs; apagar dumps e notas efêmeras no `NOTES.md`.
3. **Borda:** `.env.example` e `README.md` alinhados à tag.
4. **Reset:** reiniciar numeração; corrigir ID da tarefa ativa; promover a próxima meta (`PRONTO PARA PLANEJAMENTO`); restaurar o aviso de encerramento no `TASK.md` (não como `- [ ] **[99.1]**`).

---

## 🔄 Protocolo de Sincronização e Manutenção Inter-Branches

Como as branches `greenfield`, `brownfield`, `blackbox`, `infra` e `main` possuem árvores de arquivos intencionalmente distintas na raiz, **o comando `git merge` entre elas é estritamente proibido**, pois mesclaria arquivos de templates de forma desordenada e poluiria as raízes limpas.

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