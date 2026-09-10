# COMPONENTS.md — Contrato de componentes de UI

> Fonte da verdade para um agente gerar **peças reutilizáveis**. Sem componente/ação aqui, não há UI.
> Preenchido pela skill `component-contract`. Stack fica em ADR do repo de frontend, não neste arquivo.
> Composição em telas / rotas de SPA **não** pertence a este documento (`ui-contract` / `.agent/INTERFACE.md`).

**Status do contrato:** `Rascunho` | `Aprovado` | `Desatualizado`  
**Backend:** `[repo / nome]`  
**Base URL (dev):** `[https://… ou env]`  
**Última derivação:** `AAAA-MM-DD` · fontes: `[OpenAPI | rotas | ENDPOINTS.md | README]`

---

## 1. Contexto

- **Atores:** `[quem usa a UI]`
- **Auth:** `[nenhuma | header | cookie | …]` — header/nome exato:
- **Restrições globais do domínio:** `[ex.: equipamento off à noite]`

---

## 2. Inventário de componentes

| ID | Propósito | Reuso (hint, sem path de SPA) |
| :--- | :--- | :--- |
| `cmp-…` | | |

---

## 3. Ficha de componente (copie por ID)

### Componente `cmp-…` — `[nome]`

- **Propósito:**
- **Reuso:** `[ex.: cabeçalho operacional; painel lateral; cartão em lista]`
- **Props:**

| Prop | Origem (schema / campo) | Tipo | Obrigatório? |
| :--- | :--- | :--- | :---: |
| | | | sim/não |

- **Bindings:**

| Papel | Binding | Campos | Origem |
| :--- | :--- | :--- | :--- |
| dados | `GET /…` | | OpenAPI / arquivo |

- **Ações:**

| Ação | Binding | Pré-condição | Sucesso | Erros → copy |
| :--- | :--- | :--- | :--- | :--- |
| | `POST /…` | | | `429` → … |

- **Estados:**
  - `loading`:
  - `empty`:
  - `error` (rede / 5xx):
  - `domínio` (se houver):
- **Variantes:** `[nenhuma | …]`
- **Não mostrar:** `[ex. campos internos, stack trace]`

---

## 4. NFRs (só com evidência)

| ID | Requisito | Evidência (arquivo, status HTTP, doc) |
| :--- | :--- | :--- |
| `nfr-auth` | | |
| `nfr-quota` | | |
| `nfr-offline` | | |
| `nfr-poll` | intervalo / refresh | |

---

## 5. Inventário de rotas

Toda rota do backend aparece **uma** vez.

| Método | Path | Classe | Destino (ID componente / ação / —) |
| :---: | :--- | :--- | :--- |
| | | `component` \| `action` \| `ops-only` \| `deferred` | |

---

## 6. Fora de escopo

- `[ops-only e o que a UI não deve expor]`

## 7. Adiado

- `[rotas reais sem fluxo de usuário ainda]`
