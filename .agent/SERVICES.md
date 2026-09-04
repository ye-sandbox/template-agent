# Catálogo e Topologia de Serviços de Infraestrutura (SERVICES.md)

> 🎯 **Finalidade Deste Arquivo:** Fonte canônica viva da topologia, alocação de portas, persistência de dados e políticas de rede dos serviços provisionados neste repositório.
>
> ⚠️ **Regra Mandatória para o Agente:** NUNCA suba ou altere um contêiner no `compose.yaml` sem antes registrar e checar conflitos nas tabelas deste arquivo.

---

## 1. Alocação de Portas no Host

> Registre toda porta mapeada no host para evitar conflitos de bind (`bind: address already in use`).

| Porta Host | Protocolo | Serviço | Porta Contêiner | Exposição | Propósito / Endpoint |
| :---: | :---: | :--- | :---: | :--- | :--- |
| `9428` | TCP | `victorialogs` | `9428` | `127.0.0.1` (Local) | Ingestão e UI HTTP do VictoriaLogs |
| `3001` | TCP | `uptime-kuma` | `3001` | `0.0.0.0` (Pública) | Dashboard de monitoramento e status |
| `80` | TCP | `reverse-proxy` | `80` | `0.0.0.0` (Pública) | HTTP Gateway (Traefik / Nginx) |
| `443` | TCP | `reverse-proxy` | `443` | `0.0.0.0` (Pública) | HTTPS Gateway |

*(Tipos de Exposição: `127.0.0.1` [somente host local], `0.0.0.0` [rede pública / externa], `Rede Interna` [sem porta no host, apenas DNS Docker])*

---

## 2. Matriz de Volumes e Persistência de Dados

> Garanta que nenhum dado de produção fique efêmero dentro de contêineres e documente as permissões necessárias.

| Serviço | Tipo | Caminho no Host / Volume | Caminho no Contêiner | UID:GID | Backup Obrigatório? |
| :--- | :---: | :--- | :--- | :---: | :---: |
| `victorialogs` | Named Volume | `victorialogs_data` | `/vlogs-data` | `1000:1000` | Sim (diário) |
| `uptime-kuma` | Named Volume | `uptime_kuma_data` | `/app/data` | `1000:1000` | Sim (diário) |
| `reverse-proxy` | Bind Mount | `./config/traefik.yaml` | `/etc/traefik/traefik.yaml:ro` | `root:root` | Não (versionado em Git) |

*(Tipos de Volume: `Named Volume` [gerenciado pelo Docker], `Bind Mount` [diretório mapeado do host])*

---

## 3. Matriz de Redes Virtuais Docker

> Segregação de tráfego para segurança e contenção de blast radius.

| Nome da Rede | Driver | Escopo | Finalidade e Serviços Conectados |
| :--- | :---: | :---: | :--- |
| `proxy_public` | bridge | Interno | Roteamento de entrada (Traefik, Uptime Kuma) |
| `monitoring_internal` | bridge | Isolado | Tráfego interno de métricas e logs (VictoriaLogs, Scrapers) |
| `db_isolated` | bridge | Isolado | Acesso exclusivo de bancos de dados a seus respectivos backends |

---

## 4. Catálogo de Serviços, Imagens e Healthchecks

> Todo serviço DEVE ter imagem com tag pinada (nunca `:latest` puro) e comando de `healthcheck`.

### 📌 `victorialogs`
- **Imagem:** `victoriametrics/victoria-logs:v1.1.0`
- **Descrição:** Mecanismo de armazenamento e consulta de logs em alta performance.
- **Redes:** `monitoring_internal`
- **Healthcheck:**
  - **Comando:** `["CMD-SHELL", "wget -q --spider http://127.0.0.1:9428/health || exit 1"]`
  - **Intervalo:** `15s` | **Timeout:** `5s` | **Retries:** `3` | **Start Period:** `10s`
- **Limites de Recursos:**
  - `cpus: '1.0'` | `memory: 1024M`
- **Dependências de Boot (`depends_on`):** Nenhuma

### 📌 `uptime-kuma`
- **Imagem:** `louislam/uptime-kuma:1.23.13`
- **Descrição:** Monitoramento de uptime e dashboards públicos de status.
- **Redes:** `proxy_public`, `monitoring_internal`
- **Healthcheck:**
  - **Comando:** `["CMD-SHELL", "node extra/healthcheck.js || exit 1"]`
  - **Intervalo:** `30s` | **Timeout:** `10s` | **Retries:** `3` | **Start Period:** `30s`
- **Limites de Recursos:**
  - `cpus: '0.5'` | `memory: 512M`
- **Dependências de Boot (`depends_on`):** Nenhuma

---

## 5. Mapeamento de Variáveis Sensíveis (.env)

> Contrato de variáveis requeridas. NUNCA coloque senhas reais neste arquivo nem no Git.

| Variável | Serviço(s) | Obrigatória? | Descrição |
| :--- | :--- | :---: | :--- |
| `TZ` | Todos | Sim | Fuso horário dos contêineres (ex: `America/Sao_Paulo`) |
| `DATA_PATH` | Todos | Sim | Diretório base para persistência local (ex: `./volumes`) |
| `UPTIME_KUMA_PORT` | `uptime-kuma` | Sim | Porta externa vinculada ao Uptime Kuma |
| `VICTORIALOGS_PORT`| `victorialogs`| Sim | Porta externa de ingestão do VictoriaLogs |
