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

## Regras de Ouro deste Hub

- **NUNCA** misture arquivos de templates específicos (ex: pastas como `templates/brownfield/`) na branch `main`. Cada template deve residir na raiz de sua própria branch.
- **NUNCA** force push (`git push --force`) nas branches principais sem autorização explícita do usuário.
- **NUNCA** quebre a retrocompatibilidade do script `install.sh` na branch `brownfield`.
- **PRESERVE O CONTEXTO ENXUTO:** Mantenha os arquivos `.agent/TASK.md` e `NOTES.md` objetivos e limpos em todas as branches.