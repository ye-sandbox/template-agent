---
name: ui-prototype
description: Builds static HTML/CSS screens in proto/ from an approved .agent/INTERFACE.md. Use when the user wants HTML mockups, static screens, or a CSS prototype from a UI contract. Does not use a JS framework, does not fetch APIs, does not port to Svelte.
---

# Protótipo estático (`ui-prototype`)

Gera **só** HTML e CSS em `proto/`, a partir de `.agent/INTERFACE.md` **aprovado**. Próximo agente: [`ui-port`](../ui-port/SKILL.md). Contrato: [`ui-contract`](../ui-contract/SKILL.md).

Fonte canônica: `template-agent` (branch `main`) `.agent/skills/ui-prototype/`. No Cursor: symlink `~/.cursor/skills/ui-prototype` → esta pasta. Não copie para starters.

---

## 1. Objetivo

Materializar cada tela do mapa em HTML/CSS puro, com as **âncoras da seção 9** (`id`, `name`, `data-state`, `data-theme`). Visual revisável no browser, sem app.

---

## 2. Gatilhos

Ative quando a tarefa for:
- Telas HTML/CSS a partir do `INTERFACE.md`
- Mockup estático / proto / “abre no browser”
- Delta: tela ou widget **novo**, ou layout/copy visível mudou no contrato

**Não** ative se o contrato estiver `Rascunho`, `Desatualizado` ou locale `pendente`. **Não** ative para Svelte, Vite, fetch — isso é `ui-port`. **Não** ative só porque um path HTTP mudou sem mudança visual (isso é só `ui-port`).

---

## 3. Ferramentas

- **MCP:** nenhum obrigatório. Browser só para o humano revisar.
- **CLI:** nenhum. Arquivos estáticos.

---

## 4. Procedimento

### Passo 1 — Entrada

Exija `.agent/INTERFACE.md` com **Status `Aprovado`** e seção 8 com acordo de locale. Sem isso: pare e mande o humano voltar à `ui-contract`.

Onde escrever: `proto/` na raiz do workspace. Na primeira vez pode ser pasta só de proto; **depois da cópia**, o default é `proto/` no **repo de frontend** (ao lado do app). Esta skill **não** edita `.svelte`.

### Passo 2 — Um arquivo por tela

| Artefato | Regra |
| :--- | :--- |
| `proto/scr-….html` | Um HTML por ID do mapa. Nome do arquivo = ID. |
| `proto/css/chrome.css` | Tema (`[data-theme=light\|system\|dark]`) + chrome (seletor de idioma se `selectable`) |
| `proto/css/screens.css` | Layout das telas. Sem preprocessor obrigatório |

`index.html` opcional: lista de links para cada `scr-*.html`. Sem router.

### Passo 3 — Âncoras (obrigatório)

Copie a seção 9. Cada região existe no DOM com o `id` combinado. Campos de formulário: `name` = propriedade do schema. Estados da ficha: blocos irmãos ou regiões com `data-state="…"`. Chrome: `<html data-theme="system">` e controle de tema `light` \| `system` \| `dark` (pode ser estático / `localStorage` mínimo em `<script>` **inline só para tema/locale**, sem chamar a API).

Copy de ações e erros HTTP: texto visível no HTML (não placeholder Lorem se o contrato já tem copy).

### Passo 4 — Dados fake

Preencha com JSON de exemplo **no próprio HTML** (visível ou em comentário). **Zero** `fetch`, XHR, WebSocket, SDK.

Não crie tela que não está no mapa. Não implemente Adiado.

### Passo 5 — Parar

1. Liste os HTML gerados vs IDs do mapa (tem de bater).
2. Peça revisão **no browser** (tema system/light/dark; locale se houver seletor).
3. Não copie para outro git e não inicie `ui-port` neste turno, salvo o humano pedir explicitamente **depois** de aprovar o proto.
4. Pacote para o repo novo (humano): `.agent/INTERFACE.md` + `proto/` juntos. Sem um dos dois, o porte falha.

### Passo 6 — Delta

Tabela canônica: [`ui-contract` Passo 6](../ui-contract/SKILL.md).

- Tela/widget novo ou removido, ou copy/layout: atualize **só** os `scr-*.html` afetados. Não regenere o proto inteiro.
- Binding/NFR sem mudança visual: **não rode** esta skill.
- `proto/` no frontend pode estar atrás do Svelte se o humano aceitou débito; se for mexer no HTML, alinhe ao contrato **aprovado** atual (o copiado do backend), não ao HTML velho.

---

## 5. Vocabulário

- **Proto** — HTML/CSS estático em `proto/`
- **Âncora** — `id` / `name` / `data-state` / `data-theme` iguais ao contrato

---

## 6. Armadilhas

- ⚠️ **NÃO** use React, Vue, Svelte, Tailwind-build, bundler.
- ⚠️ **NÃO** chame o backend.
- ⚠️ **NÃO** invente `scr-*` fora do mapa.
- ⚠️ **NÃO** mude `id`/`name` “para ficar mais semântico”.
- ⚠️ **NÃO** regenere todas as telas por um campo novo numa ficha.
- 💡 **FAÇA:** CSS variables para os três temas, para o porte reusar.
- 💡 **FAÇA:** o mesmo chrome (header/tema/bandeiras) em todas as telas.

---

## 7. Checklist

- [ ] `INTERFACE.md` aprovado (locale acordado)
- [ ] Um `proto/scr-*.html` por tela do mapa
- [ ] Âncoras da seção 9 presentes no DOM
- [ ] Três temas no CSS; seletor de idioma só se `selectable`
- [ ] Zero framework, zero fetch
- [ ] Lista HTML ↔ mapa apresentada para revisão no browser
- [ ] Se delta: só os `scr-*` afetados; contrato `Aprovado` (cópia igual à do backend)
