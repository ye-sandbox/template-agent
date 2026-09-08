---
name: ui-contract
description: Derives or updates .agent/INTERFACE.md from a backend (screens, actions, bindings, empty/error states). Use for a first UI spec or after an API change (Desatualizado). Does not write UI code.
---

# Contrato de superfície de UI (`ui-contract`)

Gera **só** o documento `.agent/INTERFACE.md`. Próximo agente: [`ui-prototype`](../ui-prototype/SKILL.md) (HTML/CSS). Depois: [`ui-port`](../ui-port/SKILL.md). Molde: [`INTERFACE.template.md`](INTERFACE.template.md). Recorte: [`examples.md`](examples.md).

Fonte canônica: `template-agent` (branch `main`) `.agent/skills/ui-contract/`. No Cursor: symlink `~/.cursor/skills/ui-contract` → esta pasta. Não copie para starters.

---

## 1. Objetivo

Padronizar o handoff backend → UI: telas, ações, campos obrigatórios, bindings HTTP e NFRs **derivados de evidência**, não de persona inventada. Chrome de tema e locale (`fixed` `en` até acordo humano) são **defaults do hub** (seção 8), não telas derivadas de rota.

---

## 2. Gatilhos

Ative quando a tarefa for:
- Requisitos de interface / telas / botões a partir de uma API
- Gerar ou atualizar `.agent/INTERFACE.md`
- “Frontend para este backend” **ainda sem** código de UI
- A API mudou e a UI já existe (`Desatualizado`)

**Não** ative para implementar HTML, Svelte, escolher stack ou desenhar layout. Isso é `ui-prototype` / `ui-port`, depois do `INTERFACE.md` **aprovado**.

---

## 3. Ferramentas

- **MCP:** nenhum obrigatório. OpenAPI HTTP se o servidor estiver no ar.
- **CLI:** leitura de rotas, schemas, `openapi.json`, README, `.agent/ENDPOINTS.md` se existir.

---

## 4. Procedimento

### Passo 1 — Onde escrever

Default: `.agent/INTERFACE.md` **no repositório do backend** (o contrato vive com a API). Só escreva noutro repo se o usuário pedir explicitamente (ex. clone do frontend).

Se o arquivo já existir, **atualize** (diff de telas/rotas); não apague seções aprovadas sem dizer o que saiu. Status → `Desatualizado` até o humano reaprovar. Locale já acordado na seção 8 **não** se reabre, salvo o humano pedir.

### Passo 2 — Fontes (nessa ordem)

1. OpenAPI / Swagger gerado
2. Handlers + schemas de request/response
3. `.agent/ENDPOINTS.md` — **só rotas desta aplicação**. Ignore alvos de engenharia reversa (hardware, terceiros) a menos que a UI chame esses hosts.
4. README / docs de arquitetura — para NFRs e estados de domínio (ex. “repouso noturno”)

Não invente tela para “completar o produto”. Sem evidência → seção **Fora de escopo** ou **Adiado**, não tela nova. Chrome (seção 8) é a única superfície que **não** precisa de rota: tema sempre; locale começa `fixed` `en` e só muda no acordo do Passo 5.

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
- Seção 9: uma âncora DOM por região (`id`, `name`, `data-state`)

NFRs de domínio só com evidência: rate limit (`429` + `Retry-After`), cooldown, polling vs push, chave de API opcional, timeouts.

**Seção 8 — Chrome** (sempre, mesmo sem rota):

- **Tema:** `light` \| `system` \| `dark`; default `system`; persistência local; chrome global. Não prescreva o controle visual.
- **Locale (rascunho):** `fixed` `en`. Não invente outros idiomas nesta etapa.
- Perfil de usuário com tema/locale no schema → binding na tela de conta, não chrome duplicado.

### Passo 5 — Parar e acordar locale

1. Não gere app, componentes, CSS nem cliente HTTP de produção.
2. Mostre o mapa (telas + fora de escopo) e peça **aprovação humana**.
3. **Locale (obrigatório neste passo):** propor `fixed` `en`. Perguntar se a UI fica **só em inglês** ou se há outros idiomas.
   - Um idioma (inglês ou outro combinado) → `fixed` nesse BCP-47; sem seletor.
   - Dois ou mais → `selectable`: lista fechada pelo humano; no chrome, seletor com **bandeira do território + rótulo** por item; fallback `en` se inglês estiver na lista. Não acrescente idioma que o humano não listou.
4. Marque `Acordo humano: sim` na seção 8. Sem esse acordo o contrato não está aprovado.
5. Se pedirem HTML, Svelte ou app no mesmo turno: recuse. Próximo agente = `ui-prototype` (primeira vez ou delta visual) **depois** deste arquivo aprovado. O humano copia este arquivo para o repo de frontend — não deixe duas versões divergirem.

### Passo 6 — Delta (API já tem UI)

A UI **não** descobre a API sozinha. Ordem: backend → este arquivo (diff) → aprovação → copiar `INTERFACE.md` para o frontend → `ui-prototype` e/ou `ui-port` conforme a tabela.

| Mudou na API | Contrato | `ui-prototype` | `ui-port` |
| :--- | :--- | :--- | :--- |
| Campo, obrigatório, erro HTTP, path de ação já no mapa | Ficha + inventário | Só se copy/layout visível mudar | Binding/`name`/copy; sem redesenhar |
| NFR (poll, 429, auth) | Seção 4 | Quase nunca | Cliente HTTP / estados |
| Widget novo na **mesma** tela | Ficha + âncora §9 | HTML dessa tela | Região nova |
| Tela nova ou tela removida | Mapa + inventário | `scr-*.html` novo ou apagado | Rota nova ou removida; HTML primeiro |
| Refatoração interna (HTTP igual) | Nada, ou “sem impacto UI” | Nada | Nada |

Não descreva a mudança só no PR do backend. Sem diff neste arquivo, o frontend não mexe.

---

## 5. Vocabulário (um termo só)

- **Tela** — superfície navegável (uma rota de UI)
- **Ação** — comando do usuário mapeado a um binding
- **Widget** — região que não merece rota própria
- **Binding** — método HTTP + path + schema
- **NFR** — restrição observável (auth, quota, estado offline, latência documentada)
- **Chrome** — preferência de superfície (tema, política de locale). Não é tela. Não deriva de inventário de rotas.
- **Âncora** — `id` / `name` / `data-state` / `data-theme` que o proto e o porte devem copiar (seção 9)

---

## 6. Armadilhas

- ⚠️ **NÃO** crie tela para `GET /health` (ou equivalente).
- ⚠️ **NÃO** misture API do produto com endpoints de dispositivo/terceiro no mesmo mapa sem dizer o host.
- ⚠️ **NÃO** marque campo opcional no schema como obrigatório na UI (e o inverso).
- ⚠️ **NÃO** escolha stack (React, HTMX, …) neste documento.
- ⚠️ **NÃO** crie `/settings` nem `scr-settings` só para tema/idioma.
- ⚠️ **NÃO** marque locale `selectable` sem lista BCP-47 + território da bandeira (isso inventa i18n).
- ⚠️ **NÃO** aprove o contrato com locale `pendente`.
- ⚠️ **NÃO** reduza tema a claro/escuro: os três modos são o contrato.
- ⚠️ **NÃO** deixe o frontend chamar path que ainda não está neste arquivo.
- 💡 **FAÇA:** seletor de idioma só com 2+ locales acordados; cada opção = bandeira do território + rótulo.
- 💡 **FAÇA:** uma ação assíncrona (discover, job) com estado de progresso, não uma tela “de loading” extra.
- 💡 **FAÇA:** ações destrutivas ou de teste (ex. disparo WhatsApp) como ação explícita, nunca como tela home.

---

## 7. Checklist

- [ ] Cada binding cita método, path e origem (OpenAPI / arquivo de rota)
- [ ] Toda rota do backend está em tela, widget, ação, adiado ou fora de escopo
- [ ] Campos obrigatórios = `required` do schema (ou equivalente)
- [ ] Estados vazio / loading / erro (+ domínio, se houver) em cada tela
- [ ] Seção 8: tema `light` \| `system` \| `dark` (default `system`)
- [ ] Seção 8: locale `fixed` `en` no rascunho; acordo humano no Passo 5
- [ ] Se `selectable`: lista 2+ com BCP-47, território (bandeira) e rótulo
- [ ] Seção 9: âncora por região (`id`, `name`, `data-state`)
- [ ] Zero arquivos de UI gerados nesta execução
- [ ] Mapa + locale apresentados para revisão humana
- [ ] Se delta: lista o que entrou/saiu no mapa; status não fica `Desatualizado` sem o humano ver
