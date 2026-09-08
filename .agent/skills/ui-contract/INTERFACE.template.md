# INTERFACE.md — Contrato de superfície de UI

> Fonte da verdade para um agente de implementação. Sem tela/ação aqui, não há UI.
> Preenchido pela skill `ui-contract`. Stack fica em ADR do repo de frontend, não neste arquivo.
> Chrome (seção 8) é obrigatório mesmo sem rota de preferências.
> Duas cópias (backend e frontend) devem ser o **mesmo** arquivo após cada aprovação. API mudou → `Desatualizado` até o Passo 6 da skill.

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

---

## 8. Chrome (não deriva de rota)

Preferências de superfície. **Não** é tela de produto: não criar `scr-settings` nem rota `/settings` só por isto. Tema: especifique comportamento, não o widget. Locale `selectable`: o seletor **leva bandeira por território** (ver abaixo).

Se o backend **já** tiver perfil com tema/locale, o binding vai na ficha da tela de conta — não duplicar aqui como chrome-only.

### Tema (obrigatório)

| Campo | Valor |
| :--- | :--- |
| Valores | `light` \| `system` \| `dark` (três modos; nunca só claro/escuro) |
| Default | `system` (`prefers-color-scheme` + override) |
| Persistência | `local` (cliente) — só `binding` se existir rota de perfil |
| Onde | chrome global (header, overflow, rodapé) |

### Locale (obrigatório — acordar no Passo 5)

Rascunho da skill: `fixed` `en`. Só muda depois de acordo **explícito** com o humano (conclusão do contrato). Um idioma → `fixed`. Dois ou mais → `selectable` (seletor no chrome, **bandeira + rótulo** por item; sem bandeira solta sem BCP-47).

| Política | Quando | UI |
| :--- | :--- | :--- |
| `fixed` | Um idioma (default: inglês) | Sem seletor. Um BCP-47. |
| `selectable` | Humano listou **2+** idiomas | Seletor no chrome: bandeira do território + rótulo curto |

| Campo | Valor |
| :--- | :--- |
| Política | `fixed` \| `selectable` |
| Acordo humano | `pendente` \| `sim` (data / o que foi combinado) |
| Locales | `en` (rascunho). Se `selectable`: uma linha por idioma |
| Fallback | `en` se a lista tiver inglês; senão o primeiro da lista |
| Persistência | `local` — só `binding` se existir no schema |
| `Accept-Language` nas requests | `não` \| `sim` (só com evidência no OpenAPI/handlers) |

Tabela se `selectable` (uma linha por idioma; território ISO 3166 só para a bandeira):

| BCP-47 | Território (bandeira) | Rótulo |
| :--- | :---: | :--- |
| `en` | `US` | English |
| `[ex.: pt-BR]` | `BR` | Português |

Copy e traduções **não** entram neste arquivo. Fichas de tela no idioma de trabalho do contrato; a UI implementada segue os locales acordados.

---

## 9. Âncoras de implementação (stack-agnóstico)

O proto HTML e o porte (Svelte ou outro) **reutilizam** estes identificadores. Sem âncora aqui, o implementador não inventa `id`.

**Documento:** `<html data-theme="system">` (valores: `light` \| `system` \| `dark`). Se locale `selectable`, o seletor de bandeira vive no chrome global (mesmo markup em todas as telas).

**Por região** (preencha a partir das fichas):

| Tela | Região / widget | `id` DOM | `name` dos campos (schema) | `data-state` usados |
| :--- | :--- | :--- | :--- | :--- |
| `scr-…` | `[ex. wdg-live]` | `[igual ao widget]` | `[prop1, prop2]` | `loading` \| `empty` \| `error` \| `[domínio]` |
