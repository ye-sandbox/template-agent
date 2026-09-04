# Diretrizes e Regras do Agente (Repositório Hub de Templates)

Você é o(a) engenheiro(a) responsável pela governança, evolução e manutenção deste repositório: **Central de Templates Orientados a Agentes (ADD)**.

> 💡 **Contexto do Repositório:** Este repositório NÃO é uma aplicação final de negócio, mas sim o **Hub de Templates e Padrões de Agentes** que serve de fundação para novos projetos e adoção em legados. O projeto utiliza uma estratégia de **Branches Especializadas como Templates**.

---

## 🌿 Mapa de Branches do Repositório

- **`main` (Esta Branch):** Central de documentação, matriz de decisão, guias de governança e histórico de evolução do ecossistema de templates.
- **`greenfield`:** O starter kit puro para projetos criados do zero (com `.agent/adr/`, `.agent/skills/`, etc. na raiz).
- **`brownfield`:** O template de injeção em projetos existentes/legados (com `install.sh`, `.agent/INVARIANTS.md`, Task 00 de Discovery).

---

## Protocolo de Execução Obrigatório

1. **Sempre consulte a documentação:** Antes de alterar ou criar arquivos na `main`, consulte `AGENTS.md`, `.agent/TASK.md` e `.agent/NOTES.md`.
2. **Respeite o Isolamento das Branches:**
   - Se a tarefa for melhorar o fluxo de **projetos novos do zero**, alterne para a branch `greenfield` para aplicar e testar as mudanças.
   - Se a tarefa for melhorar o instalador ou guardrails de **código legado**, alterne para a branch `brownfield` para aplicar e testar as mudanças.
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

## 🔄 Protocolo de Sincronização e Manutenção Inter-Branches

Como as branches `greenfield`, `brownfield` e `main` possuem árvores de arquivos intencionalmente distintas na raiz, **o comando `git merge` entre elas é estritamente proibido**, pois mesclaria arquivos de templates de forma desordenada e poluiria as raízes limpas.

Para propagar melhorias de governança ou infraestrutura comum entre as branches:

### 1. Propagação de Commits Atômicos (Cherry-Pick)
Ao criar uma melhoria genérica aplicável a outras branches (ex: regras de formatação, ajustes no linter ou padrões de documentação), aplique o commit pontual:
```bash
# Estando na branch de destino (ex: greenfield ou brownfield):
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
  - Na `greenfield` e `brownfield`: Permanecem como templates canônicos limpos para o usuário final.

---

## Regras de Ouro deste Hub

- **NUNCA** execute `git merge` entre as branches especializadas (`main`, `greenfield`, `brownfield`). Propague melhorias exclusivamente via `git cherry-pick` ou checkout pontual de arquivos.
- **NUNCA** misture arquivos de templates específicos (ex: pastas como `templates/brownfield/`) na branch `main`. Cada template deve residir na raiz de sua própria branch.
- **NUNCA** force push (`git push --force`) nas branches principais sem autorização explícita do usuário.
- **NUNCA** quebre a retrocompatibilidade do script `install.sh` na branch `brownfield` nem do `init.sh` na branch `greenfield`.
- **PRESERVE O CONTEXTO ENXUTO:** Mantenha os arquivos `.agent/TASK.md` e `NOTES.md` objetivos e limpos em todas as branches.