# NOTES.md — Decisões Rápidas e Contratos do Código Legado

> Guarda o PORQUÊ das mudanças e descobertas técnicas.
> Para restrições intocáveis e peculiaridades históricas, use preferencialmente o `.agent/INVARIANTS.md`.
> Este arquivo é para decisões tomadas durante as tarefas ativas e mapeamento de contratos vigentes.

---

## Como usar este arquivo (para o agente)

1. **Leia antes de planejar qualquer tarefa.**
2. **Registre uma nova entrada quando:**
   - Um comportamento estranho ou armadilha for resolvido/investigado.
   - Um novo contrato de dados (schema/payload) for mapeado ou expandido de forma retrocompatível.
   - Um débito técnico for assumido conscientemente durante um bugfix.
3. **Mantenha as entradas curtas e objetivas.**

---

## Decisões Técnicas Recentes

### [AAAA-MM-DD] [Título da decisão ou correção no legado]

- **Contexto:** [Qual problema ou bug estava sendo corrigido]
- **Decisão:** [O que foi implementado mantendo compatibilidade]
- **Alternativas consideradas:** [Por que uma refatoração maior foi descartada em favor do escopo cirúrgico]
- **Consequências:** [Impacto ou testes de caracterização adicionados]

---

## Contratos de Dados Mapeados

### Endpoints / Filas Críticas

| Canal / Rota | Produtor | Consumidor | Schema / Observações |
|---|---|---|---|
| `[ex: POST /api/v1/orders]` | `[Frontend Legado]` | `[Worker Backend]` | `[Não permite remoção de campos antigos]` |

---

## Débitos Técnicos Assumidos

| Débito | Motivo no Legado | Quando revisitar |
|---|---|---|
| `[ex: Validação manual sem Zod/Pydantic]` | `[Módulo sem tipagem estrita total]` | `[Quando houver suíte completa de testes]` |
