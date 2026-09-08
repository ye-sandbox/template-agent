---
name: ui-port
description: Ports approved proto/ HTML/CSS plus .agent/INTERFACE.md into a frontend app. Default stack is Svelte. Use when the user wants to convert static screens to Svelte, wire API bindings, or generate the frontend from HTML mockups. Does not invent screens or redesign the proto.
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

**Não** ative sem `INTERFACE.md` **Aprovado** no frontend (a mesma revisão do backend). **Não** ative para desenhar telas novas — se o mapa ganhou `scr-*`, rode `ui-prototype` primeiro. **Não** descubra OpenAPI/rotas do backend neste repo.

---

## 3. Ferramentas

- **MCP:** nenhum obrigatório.
- **CLI:** o do repo alvo (`npm` / `pnpm` / `bun` conforme o que já existir). Não troque o package manager.

---

## 4. Procedimento

### Passo 1 — Pacote de entrada

No **repo de frontend** (novo ou existente):

```text
.agent/INTERFACE.md
proto/                  # HTML/CSS aprovados
```

Faltou um dos dois: pare. Não regenere o proto aqui (isso é `ui-prototype`).

Stack: leia `.agent/adr/` do frontend. Sem ADR de UI: **Svelte**, e registre uma ADR de uma página (“UI = Svelte; proto = fonte visual até o porte”).

### Passo 2 — Mapa 1:1

| Contrato / proto | App |
| :--- | :--- |
| `proto/scr-….html` | Uma rota / um componente de página |
| `id` / `name` / `data-state` / `data-theme` | Os mesmos atributos no markup gerado |
| `proto/css/chrome.css` | Tokens/variáveis equivalentes; não uma paleta nova |

Não funda duas telas do mapa numa só. Não invente rota que não está no mapa. Adiado permanece fora.

### Passo 3 — Comportamento

Só agora: cliente HTTP, `fetch`/load functions, headers de auth iguais ao contrato, mapeamento `429` → copy do contrato, estados `loading`/`empty`/`error`/domínio.

Tema: três modos, default `system`, persistência local (salvo binding de perfil no schema). Locale: `fixed` sem seletor; `selectable` = bandeira + rótulo por linha da seção 8.

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

1. Exija o `INTERFACE.md` **copiado** do backend após aprovação. Se o do frontend for mais velho: pare.
2. Binding/NFR/campo: ajuste o Svelte; proto só se o humano quiser zero deriva visual.
3. Tela ou widget novo: o HTML da `ui-prototype` já tem de existir neste repo. Porte só o delta; não redesenhe páginas intactas.
4. Tela removida do mapa: apague a rota do app (e o `scr-*.html` se ainda estiver no `proto/`).
5. **NÃO** adicione `fetch` a path que não está no inventário do contrato.

---

## 5. Vocabulário

- **Porte** — tradução do proto para a stack, sem redesenhar
- **Fonte visual** — `proto/` até o humano mandar o contrário
- **Fonte de comportamento** — `INTERFACE.md`

---

## 6. Armadilhas

- ⚠️ **NÃO** “alinhe o contrato” depois de ter mudado o Svelte.
- ⚠️ **NÃO** redesenhe “no estilo Svelte”.
- ⚠️ **NÃO** chame rotas que o contrato classificou `ops-only` ou Adiado.
- ⚠️ **NÃO** inventa i18n além da seção 8.
- ⚠️ **NÃO** apague `proto/` para “limpar o repo” no mesmo turno do porte.
- 💡 **FAÇA:** componentes por **região** (`id` da seção 9), não um blob por página se o HTML já tinha widgets.
- 💡 **FAÇA:** Base URL da API = a do contrato / env, não hardcode de produção.

---

## 7. Checklist

- [ ] `INTERFACE.md` + `proto/` presentes e aprovados
- [ ] Stack = ADR ou Svelte default + ADR mínima
- [ ] Uma rota de app por `scr-*`
- [ ] Âncoras da seção 9 intactas
- [ ] Bindings HTTP só do inventário do contrato
- [ ] `proto/` não apagado
- [ ] Tabela tela → arquivo apresentada para revisão no app
- [ ] Se delta: contrato frontend = backend aprovado; sem endpoint fora do inventário
