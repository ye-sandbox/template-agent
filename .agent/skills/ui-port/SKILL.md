---
name: ui-port
description: Ports approved proto (Stitch `proto/scr-<id>/code.html` or flat `proto/scr-….html`) plus .agent/INTERFACE.md into a frontend app. Default stack is Svelte 5. Copy class/keyframes/grid from proto; reuse chrome/atoms; Tailwind or UnoCSS only. Does not invent screens, duplicate components, or regenerate Stitch.
---

# Porte proto → app (`ui-port`)

Gera o **frontend** a partir de `proto/` **aprovado** + `.agent/INTERFACE.md` **aprovado**. Default de stack: **Svelte 5** (SvelteKit se o repo já for Kit; senão SPA Svelte + Vite). Idioma canônico: [`svelte.md`](svelte.md). Outra stack só se ADR do **repo alvo** disser o contrário.

Fonte canônica: `template-agent` (branch `main`) `.agent/skills/ui-port/`. No Cursor: symlink `~/.cursor/skills/ui-port` → esta pasta. Não copie para starters.

Contrato de telas: [`ui-contract`](../ui-contract/SKILL.md). Kit opcional: [`component-contract`](../component-contract/SKILL.md). Proto: [`ui-prototype`](../ui-prototype/SKILL.md).

**Por que Svelte:** o proto é HTML/CSS (Stitch ou `ui-prototype`). Svelte porta esse markup quase 1:1 (classes, âncoras, tokens), com runtime pequeno. React/Vue obrigam a reescrever o HTML em outro modelo e empurram o agente a “inventar app”. Não troque o default por gosto no turno do porte.

---

## 1. Objetivo

Portar o visual do HTML **e** montar um app na stack: chrome e átomos extraídos, estado em runes, bindings do contrato. O proto vence **pixels, copy e classes**. O `INTERFACE.md` vence comportamento (ações, campos, erros, NFRs) e a **política de superfície** da §8 (não acrescente motion/hover/peça que o HTML não tem). A stack vence **árvore de arquivos e estado** — colar `code.html` numa página não é porte.

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
.agent/INTERFACE.md          # Aprovado (obrigatório)
.agent/COMPONENTS.md         # Aprovado (opcional — mapa cmp-* → src/components)
proto/                       # um dos layouts abaixo
```

**Layout A — Stitch (preferir se existir):**

```text
proto/scr-<id>/code.html     # um HTML completo por tela do mapa
proto/scr-<id>/screen.png    # opcional (preview Stitch)
proto/bonus/DESIGN.md        # tokens; aceitar também proto/<tema>/DESIGN.md
```

Slugs Stitch (`contatos_homelab_…`, `vis_o_geral_…`) **não** são IDs. Só porte pastas `scr-<id>` iguais ao mapa. Drop cru: **renomeie** (humano ou este turno, só o nome da pasta) antes de portar. Não invente tela extra. Não deixe o slug no git.

**Ingestão do zip/pasta Stitch** (repo de **frontend**, não o hub):

| Artefato no drop | Destino |
| :--- | :--- |
| `<slug-da-tela>/code.html` de uma tela do mapa | `proto/scr-<id>/code.html` (`scr-*` = ID do `INTERFACE.md`, não o slug) |
| `screen.png` / preview da tela | `proto/scr-<id>/screen.png` |
| `<tema>/DESIGN.md` | `proto/bonus/DESIGN.md` (aceitar também `proto/<tema>/DESIGN.md`) |
| pasta de logo / mark / asset que **não** é tela do mapa | `proto/bonus/` — **não** vira `scr-*` nem rota |
| `.md` de brief gerado pelo Stitch | **não** substitui `.agent/INTERFACE.md`; opcional `proto/bonus/stitch-brief.md` |
| `INTERFACE.md` do outro git | copiar para `.agent/INTERFACE.md` **deste** frontend se for o mapa aprovado; o brief do Stitch não ganha |

Faltou HTML para algum `scr-*` do mapa: pare. Tela no drop sem ID no mapa: não porte; reporte.

**Layout B — proto da skill `ui-prototype`:**

```text
proto/scr-<id>.html
proto/css/chrome.css
proto/css/screens.css
```

Resolver: se existir `proto/scr-*/code.html` para os IDs do mapa → **A**. Senão, se existir `proto/scr-*.html` → **B**. Mistura A+B no mesmo ID: pare e pergunte. Faltou HTML para algum `scr-*` do mapa: pare (não gere HTML aqui).

Tokens: `DESIGN.md` (A) ou `chrome.css` (B). **Também** o `<style>` / `@keyframes` e o `tailwind.config` **dentro do HTML** (Stitch costuma minificar isso no `<head>`). Não inventar paleta. Classes utilitárias do nó **não** se “traduzem” para outro breakpoint.

**Motor CSS no app:** só **Tailwind** ou **UnoCSS**. Default **Tailwind** (Stitch emite essas classes; CDN → mesmo `theme.extend` no bundler). UnoCSS só se a ADR / o repo alvo **já** o usar — com preset que aceita a **mesma** string `class` do proto (`preset-wind` ou equivalente). Não escolha UnoCSS neste turno se o repo estiver vazio. **Proibido:** Bootstrap, CSS Modules como estilo principal, styled-components, DS de ficheiros `.css` no lugar das utilities. Não reescreva `md:grid-cols-3` em CSS à mão.

Faltou `INTERFACE.md` ou `proto/`: pare. Não chame `ui-prototype` se o visual canônico for Stitch.

`COMPONENTS.md`: se existir e estiver **Aprovado**, cada `cmp-*` vira arquivo em `src/components/` (props/bindings da ficha). Se não existir, **não** invente o contrato — extraia chrome e átomos repetidos do proto mesmo assim. `COMPONENTS.md` **Rascunho** ou ausente: não bloqueia o porte.

Stack: ADR do frontend. Sem ADR: **Svelte 5** + ADR de uma página (“UI = Svelte 5; proto = Stitch ou HTML até o porte”). Não escolha React/Vue neste turno.

### Passo 2 — Mapa 1:1

| Contrato / proto | App |
| :--- | :--- |
| `proto/scr-<id>/code.html` **ou** `proto/scr-<id>.html` | Uma rota / uma **página que compõe** peças; não um dump do HTML |
| `id` / `name` / `data-state` / `data-theme` (seção 9) | Os mesmos no markup gerado (no componente dono). Stitch pode usar `html.dark` sem `data-theme` — no app use o default da §8 |
| `DESIGN.md` ou `chrome.css` | Tokens equivalentes |
| Preview `btn-mode-*` / simuladores no HTML | **Não** portear como controle se o contrato disser que o estado vem da API (poll) |
| `cmp-*` (se `COMPONENTS.md` aprovado) | `src/components/…` |

Não funda duas telas do mapa numa só. Não invente rota que não está no mapa. Adiado permanece fora.

### Passo 3 — Fidelidade de markup (antes de extrair)

O Stitch vem **minificado**. Antes de escrever Svelte, abra a árvore por `id` (seção 9) — não recrie o layout de memória.

Por cada `scr-*`:

1. **Casca da página** = o wrapper do `<main>` / primeiro `div` de conteúdo (`max-w-[…]`, `px-grid-margin-*`, `grid` / `flex` / `gap-*` da **raiz**). Esse esqueleto fica na **página**. Peças preenchem regiões; **não** substituem o grid pai (`xl:grid-cols-12` + `col-span-*` não vira uma coluna de componentes empilhados).
2. **`class` literal** de cada nó com `id` e dos ancestrais de posicionamento (`relative`, `absolute`, `fixed`, `inset-*`, `z-*`, `overflow-*`, `blur-*`). Copie a string. Não troque `md:grid-cols-3` por `xl:grid-cols-4`. Não acrescente `sm:`/`lg:`/`border-*` que o HTML não tem.
3. **Motion:** todo `@keyframes` e classe custom no `<style>` do proto (`curve-stream`, `telemetry-card`, `zenith-beacon`, …) vai para o CSS do app **com o mesmo nome**, e a classe permanece no **mesmo tipo de nó** (SVG `path`, card, ping). `animate-ping` / `animate-pulse` / `transition-*` do `class` também.
4. **SVG:** `viewBox`, `d`, `stroke-dasharray`, círculos de ping — copie. Não substitua por Chart.js / Recharts “equivalente”.
5. **Proibido neste passo:** drawer, card extra, hover/`transition` novos, tipografia “mobile-first” que o proto não tem, `preview.html` paralelo.

`btn-mode-*` / simuladores: **não** virem controle se o contrato ligar o estado à API — mas o **visual** dos estados (`idle-night`, overlays, shades) continua no markup.

Falha típica: componente bem extraído com **outro** grid. Extração sem esta cópia **não** é porte.

### Passo 3b — Padrão das telas

Todas as rotas compartilham o **mesmo** chrome, as **mesmas** variantes de átomo (botão/badge/card) e os estados da ficha (`loading` / `empty` / `error` / domínio). Tela nova **não** ganha hierarquia, espaçamento ou peça “só desta rota”. O mapa (`INTERFACE.md` + proto) é o padrão — inclusive a superfície global da §8; override só no `scr-*` cuja ficha divergir. A primeira tela portada não inventa um segundo visual para as seguintes.

### Passo 4 — Estrutura da stack (Svelte)

Siga [`svelte.md`](svelte.md). Extraia **depois** da casca fiel, **antes** de ligar HTTP, nesta ordem:

1. **Chrome** compartilhado (header, nav, footer) → `src/layout/`. **Um** arquivo por peça; páginas importam, não copiam o bloco.
2. **Átomos** repetidos no proto (botão, badge, card) ou fichas `cmp-*` → `src/components/`. **Um** arquivo por variante visual. Se o markup já tem dono, **reutilize** — não crie `Button.svelte` e `PrimaryButton.svelte` para o mesmo `class` do proto.
3. **Regiões** com `id` da seção 9 → componente ou slot na página; âncora permanece no DOM.
4. **Página** por `scr-*` → só composição, bindings e estados da ficha.

Antes de criar um `.svelte` novo: procure em `src/layout/`, `src/components/` e no `COMPONENTS.md` aprovado. Delta: tela nova usa as peças já extraídas; arquivo novo só se o HTML tiver markup que ainda não existe.

Idioma Svelte 5: `$props()`, `$state`, `$derived`, `$effect`. Sem `export let`. Sem `$:`. `onMount` só para listeners do browser que não são reativos.

Porte que só gera `src/pages/*.svelte` monolíticos (header/footer/botões colados) **não** está concluído. Extraia e só então o Passo 5. Duplicar chrome/átomos entre páginas também **não** está concluído.

Outra stack (ADR): o mesmo recorte (chrome / átomos / página) com o idioma **dessa** stack; não invente Svelte no repo se a ADR proibir.

### Passo 5 — Comportamento

Só agora: cliente HTTP, `fetch`/load functions, headers de auth iguais ao contrato, mapeamento `429` → copy do contrato, estados `loading`/`empty`/`error`/domínio.

Tema: três modos se a §8 pedir; **default = valor da §8** (não forçar `system` se o contrato disser `dark`). Locale: `fixed` sem seletor; `selectable` = bandeira + rótulo. Superfície: copie os `data-*` da §8 (ou override da ficha) no documento; **não** acrescente `@keyframes` / hover / peça de marca se o proto não tiver — mesmo com motion `expressive`. Motion `none` no contrato: não reintroduza animação que o HTML também não tem.

### Passo 6 — Conflito proto vs contrato

- Visual (espaçamento, hierarquia, chrome, classes): **HTML ganha**.
- Campo obrigatório, ação, path HTTP: **contrato ganha**.
- Política de superfície (§8) vs proto: se o HTML aprovado contradisser os eixos (ex. motion `none` e o `code.html` cheio de `@keyframes`), **reporte** e não faça média. Não altere o proto neste turno a menos que o humano peça. Superfície tinha de estar acordada **antes** do Stitch / `ui-prototype`.
- Árvore de arquivos, runes, extração de peças: **stack ganha** (não é “redesenho”).
- Grid, `absolute`/`fixed`, `@keyframes`, `class` utilitária: **HTML ganha**. Extração **não** autoriza outro breakpoint nem card extra.
- Divergência visual vs contrato: reporte e não “média”. Não altere o proto neste turno a menos que o humano peça correção de proto.

### Passo 7 — Parar

1. `proto/` permanece no git como referência (não apague no porte).
2. Mostre tabela `scr-*` → arquivo de rota **e** tabela peça (layout/`cmp-*`/átomo) → arquivo.
3. Mostre tabela de fidelidade: região/`id` → `class` da raiz no proto vs no app; lista de `@keyframes` (proto vs app).
4. Peça revisão humana (browser no app **ao lado** do HTML/`screen.png`, não só o app).
5. Não volte a gerar `INTERFACE.md`.

### Passo 8 — Delta

Tabela canônica: [`ui-contract` Passo 6](../ui-contract/SKILL.md).

1. Se o contrato do frontend for o mapa Stitch (ADR): **não** exija cópia idêntica do backend. Se o fluxo for backend-canônico: exija `INTERFACE.md` copiado após aprovação; se o do frontend for mais velho, pare.
2. Binding/NFR/campo: ajuste o Svelte; proto só se o humano quiser zero deriva visual. **Não** regenere Stitch.
3. Tela nova: o HTML (Stitch `code.html` ou `ui-prototype`) já tem de existir. Porte só o delta; **reutilize** chrome/átomos já extraídos; peça nova só se o HTML tiver markup inédito. A tela nova segue o padrão das já portadas (mesmo shell, mesmas variantes). **Não** mude a casca de grid das telas que não saíram no delta.
4. Tela removida: apague a rota (e a pasta/`html` do proto se ainda estiver lá). Peças ainda usadas por outras telas **ficam**.
5. **NÃO** adicione `fetch` fora do inventário. Controles só-proto (simulador) não viram endpoint.

---

## 5. Vocabulário

- **Porte** — tradução do proto para a stack: visual 1:1 **e** estrutura do framework
- **Fonte visual** — `proto/` até o humano mandar o contrário
- **Fonte de comportamento** — `INTERFACE.md`
- **Fonte de peças** — `COMPONENTS.md` se aprovado; senão, repetição no proto
- **Dump** — um `.svelte` (ou equivalente) que é o HTML da tela inteira sem extração — falha do porte
- **Cópia** — o mesmo header/botão/card colado em duas páginas em vez de um import — falha do porte
- **Redesenho** — mesmo com peças extraídas: outro `grid-cols-*`, motion inventado, drawer/card que o proto não tem, ou visual “só desta rota” — falha do porte
- **Motor CSS** — Tailwind (default) ou UnoCSS (só se já estiver no repo/ADR); mais nenhum

---

## 6. Armadilhas

- ⚠️ **NÃO** regenere nem “achate” export Stitch (`code.html` → um arquivo plano) no turno do porte.
- ⚠️ **NÃO** porte slug Stitch (`vis_o_geral_…`, `contatos_homelab_…`) como rota; só `scr-<id>` depois de rename.
- ⚠️ **NÃO** substitua `.agent/INTERFACE.md` pelo brief `.md` que o Stitch gerar.
- ⚠️ **NÃO** duplique chrome/átomos: um arquivo por peça; páginas importam.
- ⚠️ **NÃO** introduza Bootstrap, CSS Modules como estilo principal, styled-components ou um DS de `.css` no lugar de Tailwind/UnoCSS.
- ⚠️ **NÃO** escolha UnoCSS neste turno se o repo não o tiver; default Tailwind.
- ⚠️ **NÃO** invente hierarquia/peça “só desta tela”; o padrão é o mapa + proto já portados.
- ⚠️ **NÃO** “alinhe o contrato” depois de ter mudado o Svelte.
- ⚠️ **NÃO** mude espaçamento, hierarquia, copy ou tokens “para ficar Svelte”.
- ⚠️ **NÃO** cole o `code.html` (ou `scr-*.html`) inteiro numa única página.
- ⚠️ **NÃO** recrie grid/posição/animação de memória: copie `class` e `<style>` do proto (Stitch é minificado; abra por `id`).
- ⚠️ **NÃO** empilhe componentes no lugar de `xl:grid-cols-12` / `col-span-*`.
- ⚠️ **NÃO** invente drawer, card extra, `sm:`/`xl:` ou hover que o HTML não tem.
- ⚠️ **NÃO** use `export let` / `$: ` no default Svelte 5.
- ⚠️ **NÃO** chame rotas `ops-only` ou Adiado.
- ⚠️ **NÃO** invente i18n além da seção 8.
- ⚠️ **NÃO** acrescente motion, hover ou peça “de marca” que o proto não tem; não ignore densidade/formato da §8 no que **você** adicionar.
- ⚠️ **NÃO** apague `proto/` no mesmo turno do porte.
- ⚠️ **NÃO** troque Svelte por React/Vue sem ADR no repo alvo.
- ⚠️ **NÃO** exija `COMPONENTS.md` para começar o porte; **NÃO** ignore se estiver aprovado.
- 💡 **FAÇA:** runes (`$props` / `$state` / `$derived` / `$effect`) e extração header/footer/nav + átomos. Ver [`svelte.md`](svelte.md).
- 💡 **FAÇA:** `class` literal + `@keyframes` do `<style>` do HTML nos mesmos nós; casca de grid na página.
- 💡 **FAÇA:** âncoras da seção 9 no DOM da peça dona.
- 💡 **FAÇA:** Base URL = contrato / env.

---

## 7. Checklist

- [ ] `INTERFACE.md` + `proto/` presentes e aprovados
- [ ] Stack = ADR ou Svelte 5 default + ADR mínima (não React/Vue neste turno)
- [ ] Uma rota por `scr-*` (`code.html` **ou** `scr-*.html`); página **compõe**, não é dump
- [ ] Casca de grid/`class` da raiz = proto; sem card extra nem breakpoint inventado
- [ ] `@keyframes` e classes custom do `<style>` do proto no app, nos mesmos nós
- [ ] Motor CSS = Tailwind (default) ou UnoCSS já no repo; `class` do proto literal
- [ ] Chrome em `src/layout/` (header, nav, footer); átomos em `src/components/`; **sem** cópia entre páginas
- [ ] Telas novas reusam shell/variantes das já portadas; sem visual paralelo
- [ ] Svelte 5: `$props` / `$state` / `$derived` / `$effect`; sem `export let`
- [ ] `COMPONENTS.md` aprovado → cada `cmp-*` tem arquivo; senão, átomos extraídos do proto
- [ ] Stitch: pastas = IDs do mapa; `DESIGN.md` usado para tokens
- [ ] Âncoras da seção 9; `data-*` de superfície da §8 (ou override da ficha); simuladores do HTML não viram controle se o contrato ligar estado à API
- [ ] Bindings HTTP só do inventário do contrato
- [ ] `proto/` não apagado
- [ ] Tabelas tela → rota, peça → arquivo **e** `id`/`class`/`@keyframes` proto vs app
- [ ] Se delta: contrato frontend = backend aprovado (fluxo canônico); sem endpoint fora do inventário
