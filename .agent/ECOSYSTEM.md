# Multi-Repository Ecosystem Topology & Contracts (ECOSYSTEM.md)

> **Purpose:** Canonical source of truth for topology, sibling services, shared contracts, and cross-repo boundaries in the `ye-sandbox` homelab ecosystem.
>
> **Mandatory Rules for the Agent:**
> 1. You MUST NOT break active contracts consumed by sibling repositories without an expand/contract deprecation period.
> 2. You MUST NOT attempt to directly inspect or mutate files outside this repository directory.
> 3. You MUST mock external service interactions in local automated tests.

---

## 1. Repository Topology Matrix

| Repository / Service | Role / Responsibility | Relationship | Location / Endpoint |
| :--- | :--- | :---: | :--- |
| **`offgrid-voice`** *(Current)* | Off-grid voice pipeline (`FastAPI` + `Pipecat` + `Wyoming`), CPU STT/TTS/VAD, `sqlite-vec` memory, tool orchestration | `Self` | `ye-sandbox/offgrid-voice` |
| **`hydra-llm-router`** | OpenAI v1 LLM gateway, virtual model routing (`fast` / `deep`), automatic GPU-to-CPU failover | `Upstream (Dependency)` | `http://hydra-llm-router:3000/v1` (`hydra_shared_net`) / `https://hydra-router.homelab.yegear.dev/v1` |
| **`local-llm-worker`** | Workstation GPU (`RTX 5060 Ti 16 GB`: `Gemma-4-26B-A4B-it` / `Qwen3-14B`) & Mini PC CPU (`i5-11400`: `Qwen3-4B` / `Gemma-3-4B`) inference backend | `Upstream (via hydra-llm-router)` | `ye-sandbox/local-llm-worker` |
| **`whatsapp-api`** | WhatsApp Gatekeeper API for outbound notifications and messaging tools | `Upstream (Dependency)` | `POST /send` / Redis queue (`x-api-key`) |
| **`Home Assistant / MQTT`** | Local smart home state, automations, and `View Assist` / Wyoming satellite integration | `Peer` | Local LAN (`HA_URL`, `MQTT_BROKER_URL`) |

---

## 2. Shared Contracts & Source of Truth

- **LLM Gateway Contract:** OpenAI v1 (`/v1/chat/completions`, `/v1/models`, `/v1/hydra/models`) with SSE streaming and tool calling via `hydra-llm-router`.
- **Voice Satellite Protocol:** Wyoming protocol (`TCP :10400`) and FastAPI WebSocket (`/ws/voice`) for `View Assist` / Android Kiosk / Linux clients.
- **WhatsApp Gatekeeper Contract:** `POST /send` with `x-api-key` authentication and priority queue payload schema.
- **Drift Prevention:** All external HTTP/MQTT/Wyoming clients MUST be wrapped behind typed `Pydantic v2` schemas and mocked in `pytest` suites.

---

## 3. Cross-Repo Interfaces Catalog

### A. Consumed by `offgrid-voice` (Upstream Dependencies)

| Source Service | Protocol / Transport | Target Endpoint / Topic | Contract / Schema | Fallback / Blast Radius |
| :--- | :---: | :--- | :--- | :--- |
| **`hydra-llm-router`** | HTTP / SSE | `POST /v1/chat/completions` (`model="fast"`) | OpenAI v1 Chat Completions + Tool Calls | Automatic router failover from GPU workstation to Mini PC `i5-11400` CPU (`Qwen3-4B` / `Gemma-3-4B`) |
| **`whatsapp-api`** | HTTP / Redis | `POST /send` | Gatekeeper JSON + `x-api-key` | Tool returns structured error to voice assistant; non-fatal to voice loop |
| **`Home Assistant / MQTT`** | HTTP / MQTT | `/api/services/*`, `homeassistant/#` | HA Service Call JSON / MQTT payloads | Tool returns structured timeout/offline message; non-fatal to voice loop |

### B. Exposed by `offgrid-voice` (Downstream Consumers)

| Route / Topic | Consumer(s) | Payload / Schema | Breaking Change Risk | Deprecation Policy |
| :--- | :--- | :--- | :---: | :--- |
| `TCP :10400` (Wyoming) | Echo Dot (`Firebreak`), Linux Wyoming client, HA | Wyoming Audio / ASR / TTS events | **MEDIUM** | Preserve standard Wyoming event framing |
| `WS /ws/voice` | Echo Show (`View Assist`), Android Kiosk | Streaming PCM + JSON control frames | **MEDIUM** | Versioned WebSocket message envelope |
| `GET /health` | Docker / Traefik / Monitoring | `{"status": "ok"}` | **LOW** | Standard healthcheck contract |

---

## 4. Blast Radius & Contract Evolution Rules

1. **Additive-First (Expand / Contract):** Never delete, rename, or change types of active external schemas without an expand/contract period.
2. **Hermetic Testing & Zero Cross-Repo Mutation:** Automated `pytest` suites MUST NOT require live network access to `hydra-llm-router`, `whatsapp-api`, or Home Assistant; mock all external boundaries.
3. **Network Boundary:** Co-located containers attach to `hydra_shared_net` (`external: true`) only; never attach to `hydra_router_internal` or `hydra_ai_net`.
