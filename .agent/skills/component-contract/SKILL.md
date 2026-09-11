---
name: component-contract
description: Derives .agent/COMPONENTS.md — reusable UI component inventory (props, bindings, actions, empty/error/domain states) from an existing backend. Use when the user wants a component kit, reusable widgets, component contract, or COMPONENTS.md from OpenAPI/routes. Does not write UI code and does not invent screens or UI routes.
---

# Contrato de componentes de UI (`component-contract`)

Gera **só** o documento `.agent/COMPONENTS.md`. Outro agente implementa os componentes **depois** de revisão humana. Molde: [`COMPONENTS.template.md`](COMPONENTS.template.md). Recorte de exemplo: [`examples.md`](examples.md).

Fonte canônica: `template-agent` (branch `main`) `.agent/skills/component-contract/`. No Cursor: symlink `~/.cursor/skills/component-contract` → esta pasta. Não copie para starters.

Irmã de [`ui-contract`](../ui-contract/SKILL.md): aquela skill mapeia **telas**; esta pede **peças reutilizáveis**. Não misture os artefatos. Depois de **aprovado**, o [`ui-port`](../ui-port/SKILL.md) **pode** mapear `cmp-*` → `src/components/`; esta skill **não** gera código.

---

## 1. Objetivo

Padronizar o handoff backend → kit de UI: componentes, props, ações, bindings HTTP e NFRs **derivados de evidência**. O implementador gera componentes isolados para reuso; composição em telas é outro turno.

---

## 2. Gatilhos

Ative quando a tarefa for:
- Inventário de componentes / widgets reutilizáveis a partir de uma API
- Gerar ou atualizar `.agent/COMPONENTS.md`
- “Gere os componentes desta API” **ainda sem** código de UI e **sem** mapa de rotas de SPA

**Não** ative para:
- Mapa de telas / rotas de UI → `ui-contract`
- Implementar React/Vue/CSS, escolher stack, ou desenhar layout de página

---

## 3. Ferramentas

- **MCP:** nenhum obrigatório. OpenAPI HTTP se o servidor estiver no ar.
- **CLI:** leitura de rotas, schemas, `openapi.json`, README, `.agent/ENDPOINTS.md` se existir.

---

## 4. Procedimento

### Passo 1 — Onde escrever

Default: `.agent/COMPONENTS.md` **no repositório do backend** (o contrato vive com a API). Só escreva noutro repo se o usuário pedir explicitamente.

Se o arquivo já existir, **atualize** (diff de componentes/rotas); não apague fichas aprovadas sem dizer o que saiu.

Não escreva em `.agent/INTERFACE.md`.

### Passo 2 — Fontes (nessa ordem)

1. OpenAPI / Swagger gerado
2. Handlers + schemas de request/response
3. `.agent/ENDPOINTS.md` — **só rotas desta aplicação**. Ignore alvos de engenharia reversa (hardware, terceiros) a menos que o componente chame esses hosts.
4. README / docs de arquitetura — para NFRs e estados de domínio

Não invente componente para “completar o design system”. Sem evidência → **Fora de escopo** ou **Adiado**.

### Passo 3 — Classificar cada rota

| Classe | Critério | Vai para |
| :--- | :--- | :--- |
| `ops-only` | Health, metrics, debug, probes | Fora de escopo |
| `component` | GET (ou bloco) que merece peça isolada e reutilizável | Ficha `cmp-…` |
| `action` | POST/PUT/PATCH/DELETE (ou GET de comando) | Ação **de um** componente |
| `deferred` | Existe, mas não há ator/fluxo evidenciado | Adiado |

Critério de **um** vs **vários** componentes: reuso e ciclo de vida, não navegação.

- Mesmo schema + mesmo padrão de interação → **um** componente (variantes/slots se necessário).
- GETs do mesmo recurso com ciclos distintos (live vs histórico vs status) → componentes **separados**, a menos que o schema e o refresh sejam idênticos.
- Uma ação pertence ao componente que já exibe o recurso que ela muta. Não crie `cmp-loading` só para job assíncrono: progresso é estado do componente dono.

### Passo 4 — Preencher o molde

Copie [`COMPONENTS.template.md`](COMPONENTS.template.md) e preencha. Por componente, obrigatório:

- Props derivadas do schema (nome, tipo, obrigatório = `required` da API)
- Bindings: método + path + origem
- Ações com pré-condição, sucesso, erros HTTP mapeados a copy
- Estados: `loading`, `empty`, `error`, e estados de **domínio** documentados no backend
- Auth: header/cookie/query iguais ao backend
- Hint de reuso (onde a peça encaixa) **sem** path de SPA

NFRs só com evidência: rate limit (`429` + `Retry-After`), cooldown, polling vs push, chave de API opcional, timeouts.

### Passo 5 — Parar

1. Não gere app, componentes em código, CSS nem cliente HTTP de produção.
2. Mostre o mapa (lista de `cmp-…` + o que ficou de fora) e peça **aprovação humana**.
3. Se pedirem implementação no mesmo turno: recuse até o `COMPONENTS.md` estar aprovado. Implementação = `ui-port` (com telas + proto) ou um turno só de kit, **depois** da aprovação.

---

## 5. Vocabulário (um termo só)

- **Componente** — peça reutilizável com contrato de props; não é rota de UI
- **Prop** — entrada tipada derivada do schema (ou de um recorte dele)
- **Ação** — comando do usuário mapeado a um binding
- **Binding** — método HTTP + path + schema
- **Variante** — mesma peça, visual/estado diferente com evidência no backend
- **NFR** — restrição observável (auth, quota, estado offline, latência documentada)

Não use **tela**, **rota de UI** ou `scr-…` neste artefato.

---

## 6. Armadilhas

- ⚠️ **NÃO** crie componente para `GET /health` (ou equivalente).
- ⚠️ **NÃO** invente mapa de telas (`/dashboard`, nav pai/filho) — isso é `ui-contract`.
- ⚠️ **NÃO** misture API do produto com endpoints de dispositivo/terceiro no mesmo mapa sem dizer o host.
- ⚠️ **NÃO** marque campo opcional no schema como prop obrigatória (e o inverso).
- ⚠️ **NÃO** escolha stack (React, HTMX, …) neste documento.
- 💡 **FAÇA:** job assíncrono (discover) como ação + estado de progresso no componente dono.
- 💡 **FAÇA:** ações destrutivas ou de teste (ex. disparo WhatsApp) como ação explícita de um componente, nunca como “home”.

---

## 7. Checklist

- [ ] Cada binding cita método, path e origem (OpenAPI / arquivo de rota)
- [ ] Toda rota do backend está em componente, ação, adiado ou fora de escopo
- [ ] Props obrigatórias = `required` do schema (ou equivalente)
- [ ] Estados vazio / loading / erro (+ domínio, se houver) em cada componente
- [ ] Zero rotas de SPA e zero `scr-…` no arquivo
- [ ] Zero arquivos de UI gerados nesta execução
- [ ] Mapa apresentado para revisão humana
