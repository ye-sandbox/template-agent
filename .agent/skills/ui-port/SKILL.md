---
name: ui-port
description: Ports approved proto (Stitch `proto/scr-<id>/code.html` or flat `proto/scr-….html`) plus .agent/INTERFACE.md into a frontend app. Default stack is Svelte. Use when converting HTML mockups or Stitch exports to Svelte. Does not invent screens or regenerate Stitch.
---

# Porte proto → app (`ui-port`)

Gera o **frontend** a partir de `proto/` **aprovado** + `.agent/INTERFACE.md` **aprovado**. Default de stack: **Svelte** (SvelteKit se o repo já for Kit; senão SPA Svelte). Outra stack só se ADR do **repo alvo** disser o contrário.

Fonte canônica: `template-agent` (branch `main`) `.agent/skills/ui-port/`. No Cursor: symlink `~/.cursor/skills/ui-port` → esta pasta. Não copie para starters.

Contrato: [`ui-contract`](../ui-contract/SKILL.md). Proto: [`ui-prototype`](../ui-prototype/SKILL.md).

---

## 1. Objetivo

Portar 1:1 o visual do HTML e ligar os **bindings** do contrato. O proto vence o visual. O `INTERFACE.md` vence comportamento (ações, campos, erros, NFRs).

---

## 2. Gatilhos

Ative quando a tarefa for:
- Porte HTML → Svelte (ou stack da ADR)
- “Frontend a partir destas telas”
- Ligar API nas telas já prototipadas
- Delta: contrato atualizado (cópia do backend) e bindings/rotas a ajustar no app

**Não** ative sem `INTERFACE.md` **Aprovado** no frontend. Se o mapa do frontend **diverge** do backend de propósito (ADR / Stitch), o arquivo **deste** git vence — não exija byte-a-byte o `INTERFACE.md` do backend. **Não** ative para desenhar telas novas: HTML Stitch novo ou `ui-prototype` primeiro. **Não** descubra OpenAPI neste repo. **Não** regenere `proto/` (Stitch ou HTML da skill).

---

## 3. Ferramentas

- **MCP:** nenhum obrigatório.
- **CLI:** o do repo alvo (`npm` / `pnpm` / `bun` conforme o que já existir). Não troque o package manager.

---

## 4. Procedimento

### Passo 1 — Pacote de entrada

No **repo de frontend** (novo ou existente):

```text
.agent/INTERFACE.md          # Aprovado
proto/                       # um dos layouts abaixo
```

**Layout A — Stitch (preferir se existir):**

```text
proto/scr-<id>/code.html     # um HTML completo por tela do mapa
proto/scr-<id>/screen.png    # opcional (preview Stitch)
proto/bonus/DESIGN.md        # tokens; aceitar também proto/<tema>/DESIGN.md
```

Slugs Stitch com acento quebrado (`vis_o_geral_…`) **não** são IDs. Só porte pastas `scr-<id>` iguais ao mapa. Se o drop ainda estiver com slug: pare e peça rename (não invente tela extra).

**Layout B — proto da skill `ui-prototype`:**

```text
proto/scr-<id>.html
proto/css/chrome.css
proto/css/screens.css
```

Resolver: se existir `proto/scr-*/code.html` para os IDs do mapa → **A**. Senão, se existir `proto/scr-*.html` → **B**. Mistura A+B no mesmo ID: pare e pergunte. Faltou HTML para algum `scr-*` do mapa: pare (não gere HTML aqui).

Tokens: `DESIGN.md` (A) ou `chrome.css` (B). Não inventar paleta. Tailwind CDN no Stitch → equivalente no bundler do app (classes/tokens), sem redesenhar.

Faltou `INTERFACE.md` ou `proto/`: pare. Não chame `ui-prototype` se o visual canônico for Stitch.

Stack: ADR do frontend. Sem ADR: **Svelte** + ADR de uma página (“UI = Svelte; proto = Stitch ou HTML até o porte”).

### Passo 2 — Mapa 1:1

| Contrato / proto | App |
| :--- | :--- |
| `proto/scr-<id>/code.html` **ou** `proto/scr-<id>.html` | Uma rota / uma página |
| `id` / `name` / `data-state` / `data-theme` (seção 9) | Os mesmos no markup gerado. Stitch pode usar `html.dark` sem `data-theme` — no app use o default da §8 |
| `DESIGN.md` ou `chrome.css` | Tokens equivalentes |
| Preview `btn-mode-*` / simuladores no HTML | **Não** portear como controle se o contrato disser que o estado vem da API (poll) |

Não funda duas telas do mapa numa só. Não invente rota que não está no mapa. Adiado permanece fora.

### Passo 3 — Comportamento

Só agora: cliente HTTP, `fetch`/load functions, headers de auth iguais ao contrato, mapeamento `429` → copy do contrato, estados `loading`/`empty`/`error`/domínio.

Tema: três modos se a §8 pedir; **default = valor da §8** (não forçar `system` se o contrato disser `dark`). Locale: `fixed` sem seletor; `selectable` = bandeira + rótulo.

### Passo 4 — Conflito proto vs contrato

- Visual (espaçamento, hierarquia, chrome): **HTML ganha**.
- Campo obrigatório, ação, path HTTP: **contrato ganha**.
- Divergência: reporte e não “média”. Não altere o proto neste turno a menos que o humano peça correção de proto.

### Passo 5 — Parar

1. `proto/` permanece no git como referência (não apague no porte).
2. Mostre tabela `scr-*` → arquivo de rota.
3. Peça revisão humana (browser no app, não só o HTML).
4. Não volte a gerar `INTERFACE.md`.

### Passo 6 — Delta

Tabela canônica: [`ui-contract` Passo 6](../ui-contract/SKILL.md).

1. Se o contrato do frontend for o mapa Stitch (ADR): **não** exija cópia idêntica do backend. Se o fluxo for backend-canônico: exija `INTERFACE.md` copiado após aprovação; se o do frontend for mais velho, pare.
2. Binding/NFR/campo: ajuste o Svelte; proto só se o humano quiser zero deriva visual. **Não** regenere Stitch.
3. Tela nova: o HTML (Stitch `code.html` ou `ui-prototype`) já tem de existir. Porte só o delta.
4. Tela removida: apague a rota (e a pasta/`html` do proto se ainda estiver lá).
5. **NÃO** adicione `fetch` fora do inventário. Controles só-proto (simulador) não viram endpoint.

---

## 5. Vocabulário

- **Porte** — tradução do proto para a stack, sem redesenhar
- **Fonte visual** — `proto/` até o humano mandar o contrário
- **Fonte de comportamento** — `INTERFACE.md`

---

## 6. Armadilhas

- ⚠️ **NÃO** regenere nem “achate” export Stitch (`code.html` → um arquivo plano) no turno do porte.
- ⚠️ **NÃO** porte slug Stitch (`vis_o_geral_…`) como rota; só `scr-<id>`.
- ⚠️ **NÃO** “alinhe o contrato” depois de ter mudado o Svelte.
- ⚠️ **NÃO** redesenhe “no estilo Svelte”.
- ⚠️ **NÃO** chame rotas `ops-only` ou Adiado.
- ⚠️ **NÃO** invente i18n além da seção 8.
- ⚠️ **NÃO** apague `proto/` no mesmo turno do porte.
- 💡 **FAÇA:** componentes por região (`id` da seção 9).
- 💡 **FAÇA:** Base URL = contrato / env.

---

## 7. Checklist

- [ ] `INTERFACE.md` + `proto/` presentes e aprovados
- [ ] Stack = ADR ou Svelte default + ADR mínima
- [ ] Uma rota por `scr-*` (`code.html` **ou** `scr-*.html`)
- [ ] Stitch: pastas = IDs do mapa; `DESIGN.md` usado para tokens
- [ ] Âncoras da seção 9; simuladores do HTML não viram controle se o contrato ligar estado à API
- [ ] Bindings HTTP só do inventário do contrato
- [ ] `proto/` não apagado
- [ ] Tabela tela → arquivo apresentada para revisão no app
- [ ] Se delta: contrato frontend = backend aprovado; sem endpoint fora do inventário
