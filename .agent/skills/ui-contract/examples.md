# Recorte: `solar-energy` (API Solplanet)

Ilustra classificação. Não é o contrato completo — o agente preenche `INTERFACE.md` no repo alvo.

## Rotas → classe

| Método | Path | Classe | Por quê |
| :---: | :--- | :--- | :--- |
| `GET` | `/health` | `ops-only` | Probe; não é produto |
| `GET` | `/api/status` | `widget` | Bloco “estado do inversor/coletor” na tela operacional |
| `GET` | `/api/telemetry/live` | `widget` | Leitura instantânea na mesma tela |
| `GET` | `/api/telemetry/today` | `widget` | Curva do dia na mesma tela |
| `GET` | `/api/telemetry/buffer` | `widget` ou `deferred` | Série RAM; só tela própria se o usuário pedir histórico fino |
| `POST` | `/api/inverter/discover` | `action` | Comando longo; progresso na tela operacional, não tela extra |
| `POST` | `/api/notifications/test` | `action` | Teste WhatsApp; não é home; auth opcional `x-api-key`; `429` + cooldown |

## Uma tela, vários widgets

`scr-ops` `/` — superfície única: status + live + curva. `has_data: false` no live → estado de domínio “repouso / sem leitura”, não erro genérico (README/API já descrevem sono noturno do dongle).

## Chrome (seção 8 — não vem das rotas)

Tema: `light` | `system` | `dark`, default `system`, persistência local no chrome (não há `PUT` de preferências na API). Locale no rascunho: `fixed` `en`. Superfície no rascunho: eixos `pendente` — **não** inferir `operator` do path `/api/inverter`. No Passo 5 o humano confirma inglês só (ou p.ex. `en` + `pt-BR` → `selectable` com bandeiras `US` e `BR`) **e** a superfície, p.ex. global `operator` + `industrial` + `functional` + `plain` + `desktop`. `Accept-Language` não aparece nos handlers.

Override: neste recorte nenhuma ficha diverge (home operacional = o default). Exemplo de override, se o humano pedisse um `scr-public`: na ficha, `audiência = layperson`, `densidade = minimal`, `formato = touch`; o resto herda.

## Âncoras (seção 9)

`scr-ops` → `id="scr-ops"`; widgets `wdg-status`, `wdg-live`, `wdg-today`. Estados no live: `loading`, `empty`, `error`, `idle-night` (`has_data: false`). `html data-theme` e, após acordo, `data-audience` / `data-density` / `data-motion` / `data-copy` / `data-format`. Sem seletor de idioma no rascunho.

## NFR com evidência

- `nfr-quota`: `POST /api/notifications/test` → `429` + `Retry-After` (`routes.py`).
- `nfr-auth`: chave `SOLPLANET_API_KEY` / header `x-api-key` só nessa ação, não em GETs de telemetria.
- `nfr-offline`: inversor/dongle sem energia → falha de rede ou payload sem dados; UI não trata como pane.
