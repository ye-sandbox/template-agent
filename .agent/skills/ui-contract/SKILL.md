---
name: ui-contract
description: Derives .agent/INTERFACE.md — functional and non-functional UI requirements (screens, actions, required fields, endpoint bindings, empty/error states) from an existing backend. Use when the user wants a frontend spec, UI contract, screen inventory, interface requirements, or to generate INTERFACE.md from OpenAPI/routes. Does not write UI code.
---

# Contrato de superfície de UI (`ui-contract`)

Gera **só** o documento `.agent/INTERFACE.md`. Outro agente implementa a UI **depois** de revisão humana. Molde: [`INTERFACE.template.md`](INTERFACE.template.md). Recorte de exemplo: [`examples.md`](examples.md).

Fonte canônica: `template-agent` (branch `main`) `.agent/skills/ui-contract/`. No Cursor: symlink `~/.cursor/skills/ui-contract` → esta pasta. Não copie para starters.

---

## 1. Objetivo

Padronizar o handoff backend → UI: telas, ações, campos obrigatórios, bindings HTTP e NFRs **derivados de evidência**, não de persona inventada.

---

## 2. Gatilhos

Ative quando a tarefa for:
- Requisitos de interface / telas / botões a partir de uma API
- Gerar ou atualizar `.agent/INTERFACE.md`
- “Frontend para este backend” **ainda sem** código de UI

**Não** ative para implementar componentes, escolher React/Vue, ou desenhar layout visual. Isso é outro agente, lendo o `INTERFACE.md` aprovado.

---

## 3. Ferramentas

- **MCP:** nenhum obrigatório. OpenAPI HTTP se o servidor estiver no ar.
- **CLI:** leitura de rotas, schemas, `openapi.json`, README, `.agent/ENDPOINTS.md` se existir.

---

## 4. Procedimento

### Passo 1 — Onde escrever

Default: `.agent/INTERFACE.md` **no repositório do backend** (o contrato vive com a API). Só escreva noutro repo se o usuário pedir explicitamente (ex. clone do frontend).

Se o arquivo já existir, **atualize** (diff de telas/rotas); não apague seções aprovadas sem dizer o que saiu.

### Passo 2 — Fontes (nessa ordem)

1. OpenAPI / Swagger gerado
2. Handlers + schemas de request/response
3. `.agent/ENDPOINTS.md` — **só rotas desta aplicação**. Ignore alvos de engenharia reversa (hardware, terceiros) a menos que a UI chame esses hosts.
4. README / docs de arquitetura — para NFRs e estados de domínio (ex. “repouso noturno”)

Não invente tela para “completar o produto”. Sem evidência → seção **Fora de escopo** ou **Adiado**, não tela nova.

### Passo 3 — Classificar cada rota

| Classe | Critério | Vai para |
| :--- | :--- | :--- |
| `ops-only` | Health, metrics, debug, probes | Fora de escopo (não é tela) |
| `screen` | GET que é uma vista de estado para um humano | Ficha de tela |
| `widget` | GET que só alimenta um bloco de outra tela | Campo/região da tela pai |
| `action` | POST/PUT/PATCH/DELETE (ou GET de comando) | Ação na tela que já mostra o recurso |
| `deferred` | Existe, mas não há ator/fluxo evidenciado | Adiado |

Uma tela ≠ um GET. Agrupe GETs do mesmo recurso (status + live + curva do dia → uma superfície, widgets distintos).

### Passo 4 — Preencher o molde

Copie [`INTERFACE.template.md`](INTERFACE.template.md) e preencha. Por tela, obrigatório:

- Rota de UI (path proposto, stack-agnóstico)
- Bindings: método + path + campos do schema (obrigatório sim/não)
- Ações com pré-condição, sucesso, erros HTTP mapeados a copy
- Estados: `loading`, `empty`, `error`, e estados de **domínio** documentados no backend
- Auth: header/cookie/query iguais ao backend

NFRs só com evidência: rate limit (`429` + `Retry-After`), cooldown, polling vs push, chave de API opcional, timeouts.

### Passo 5 — Parar

1. Não gere app, componentes, CSS nem cliente HTTP de produção.
2. Mostre o mapa (lista de telas + o que ficou de fora) e peça **aprovação humana**.
3. Se pedirem implementação no mesmo turno: recuse até o `INTERFACE.md` estar aprovado.

---

## 5. Vocabulário (um termo só)

- **Tela** — superfície navegável (uma rota de UI)
- **Ação** — comando do usuário mapeado a um binding
- **Widget** — região que não merece rota própria
- **Binding** — método HTTP + path + schema
- **NFR** — restrição observável (auth, quota, estado offline, latência documentada)

---

## 6. Armadilhas

- ⚠️ **NÃO** crie tela para `GET /health` (ou equivalente).
- ⚠️ **NÃO** misture API do produto com endpoints de dispositivo/terceiro no mesmo mapa sem dizer o host.
- ⚠️ **NÃO** marque campo opcional no schema como obrigatório na UI (e o inverso).
- ⚠️ **NÃO** escolha stack (React, HTMX, …) neste documento.
- 💡 **FAÇA:** uma ação assíncrona (discover, job) com estado de progresso, não uma tela “de loading” extra.
- 💡 **FAÇA:** ações destrutivas ou de teste (ex. disparo WhatsApp) como ação explícita, nunca como tela home.

---

## 7. Checklist

- [ ] Cada binding cita método, path e origem (OpenAPI / arquivo de rota)
- [ ] Toda rota do backend está em tela, widget, ação, adiado ou fora de escopo
- [ ] Campos obrigatórios = `required` do schema (ou equivalente)
- [ ] Estados vazio / loading / erro (+ domínio, se houver) em cada tela
- [ ] Zero arquivos de UI gerados nesta execução
- [ ] Mapa apresentado para revisão humana
