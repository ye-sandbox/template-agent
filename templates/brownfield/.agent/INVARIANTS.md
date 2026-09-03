# INVARIANTS.md — Invariantes e Regras Intocáveis do Sistema

> 🧱 **O Princípio do Muro de Chesterton:**
> *"Nunca remova uma regra, filtro ou trecho de código estranho até descobrir por que ele foi colocado ali."*
>
> Este arquivo é a fonte da verdade para **comportamentos, peculiaridades e contratos do sistema legado** que PARECEM errados, redundantes ou feios à primeira vista, mas que **NÃO DEVEM SER ALTERADOS** sem aprovação explícita e justificada do desenvolvedor.

---

## Como usar este arquivo (para o agente)

1. **Consulte antes de qualquer alteração:** Sempre leia este arquivo antes de planejar mudanças em modelos, contratos de rotas ou queries.
2. **Atualize ao descobrir uma regra implícita:** Ao investigar um bug ou ler o código legado e descobrir que um trecho existe por uma limitação histórica de terceiros, documente-o imediatamente aqui.
3. **Não confunda com `NOTES.md`:** O `NOTES.md` guarda decisões recentes e contratos gerais. O `INVARIANTS.md` guarda especificamente **restrições inquebráveis e armadilhas do sistema existente**.

---

## 1. Contratos Externos Rígidos e Legados

| Ponto de Contato | Regra Inquebrável | Motivo / Impacto |
| :--- | :--- | :--- |
| `[ex: /api/v1/webhook]` | `[Manter header X-Legacy-Token]` | `[Parceiro externo não suporta Bearer token]` |
| `[ex: Campo customer_code]` | `[Manter string com zeros à esquerda]` | `[ERP legado quebra se receber número inteiro]` |
| `[ex: Payload de Pagamento]` | `[Valores monetários em centavos (inteiro)]` | `[Gateway não aceita float]` |

---

## 2. Dependências e Ambiente Congelados

- **Versões Bloqueadas:**
  - `[ex: Biblioteca X na versão 2.4.1]`: Não atualizar. Versões 3.x removem suporte ao protocolo legado usado por nossos workers.
  - `[ex: Python/Node na versão X]`: Não alterar versão no Dockerfile sem validação de compilação C/libs nativas.

---

## 3. "Gambiarras" Justificadas e Comportamentos Não-Óbvios

Documente aqui trechos de código que parecem anti-padrões, mas têm razão de ser:

### [Nome do Módulo ou Função]
- **O que o código faz:** [ex: Um `sleep(200ms)` antes de confirmar a escrita no banco]
- **Por que parece errado:** [ex: Introduz latência síncrona artificial]
- **Por que NÃO DEVE ser removido:** [ex: O banco secundário possui replicação assíncrona com lag de leitura e o webhook seguinte bate imediatamente na réplica]

---

## 4. Regras de Negócio Críticas Não-Documentadas

- `[Regra 1]`: [ex: Clientes corporativos nunca podem ter o status 'arquivado' alterado diretamente via API, somente via fila de expiração].
- `[Regra 2]`: [ex: Nomes de usuários não podem ter case alterado porque a busca no banco é case-sensitive histórica].
