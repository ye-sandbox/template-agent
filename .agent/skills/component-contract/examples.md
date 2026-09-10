# Recorte: `solar-energy` (API Solplanet)

Ilustra classificação em **componentes**. Não é o contrato completo — o agente preenche `COMPONENTS.md` no repo alvo. Não inventa telas.

## Rotas → classe

| Método | Path | Classe | Componente dono | Por quê |
| :---: | :--- | :--- | :--- | :--- |
| `GET` | `/health` | `ops-only` | — | Probe; não é produto |
| `GET` | `/api/status` | `component` | `cmp-inverter-status` | Ciclo lento; estado do inversor/coletor |
| `GET` | `/api/telemetry/live` | `component` | `cmp-telemetry-live` | Refresh curto; leitura instantânea |
| `GET` | `/api/telemetry/today` | `component` | `cmp-today-curve` | Série do dia; outro ciclo de vida |
| `GET` | `/api/telemetry/buffer` | `component` ou `deferred` | `cmp-buffer-series` | Série RAM; só peça própria se o usuário pedir histórico fino |
| `POST` | `/api/inverter/discover` | `action` | `cmp-inverter-status` | Comando longo; progresso no status, não componente extra |
| `POST` | `/api/notifications/test` | `action` | `cmp-notify-test` | Teste WhatsApp; auth opcional `x-api-key`; `429` + cooldown |

## Por que não uma peça só

`status`, `live` e `today` compartilham o domínio solar, mas **não** o mesmo refresh nem o mesmo schema de resposta. Três componentes. Um agente de implementação pode **compor** os três depois; este contrato não define `/` nem `scr-ops`.

`has_data: false` no live → estado de domínio “repouso / sem leitura” em `cmp-telemetry-live`, não erro genérico (README/API já descrevem sono noturno do dongle).

## NFR com evidência

- `nfr-quota`: `POST /api/notifications/test` → `429` + `Retry-After` (`routes.py`) — na ficha de `cmp-notify-test`.
- `nfr-auth`: chave `SOLPLANET_API_KEY` / header `x-api-key` só nessa ação, não nos GETs de telemetria.
- `nfr-offline`: inversor/dongle sem energia → falha de rede ou payload sem dados; o componente não trata como pane.
- `nfr-poll`: intervalos distintos por componente (live vs status vs curva), se documentados no backend.
