# INTERFACE.md — Contrato de superfície de UI

> Fonte da verdade para um agente de implementação. Sem tela/ação aqui, não há UI.
> Preenchido pela skill `ui-contract`. Stack fica em ADR do repo de frontend, não neste arquivo.

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

## 2. Mapa de telas

| ID | Rota de UI | Propósito | Tela pai / nav |
| :--- | :--- | :--- | :--- |
| `scr-…` | `/…` | | |

---

## 3. Ficha de tela (copie por ID)

### Tela `scr-…` — `[nome]`

- **Rota de UI:** `/…`
- **Propósito:**
- **Widgets / regiões:**

| Região | Binding | Campos visíveis | Obrigatório na UI? |
| :--- | :--- | :--- | :---: |
| | `GET /…` | | sim/não |

- **Ações:**

| Ação | Binding | Pré-condição | Sucesso | Erros → copy |
| :--- | :--- | :--- | :--- | :--- |
| | `POST /…` | | | `429` → … |

- **Estados:**
  - `loading`:
  - `empty`:
  - `error` (rede / 5xx):
  - `domínio` (se houver):
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

| Método | Path | Classe | Destino (ID tela / ação / —) |
| :---: | :--- | :--- | :--- |
| | | `screen` \| `widget` \| `action` \| `ops-only` \| `deferred` | |

---

## 6. Fora de escopo

- `[ops-only e o que a UI não deve expor]`

## 7. Adiado

- `[rotas reais sem fluxo de usuário ainda]`
