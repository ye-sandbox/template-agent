# NOTES.md — Active Contracts and Runtime Memory

> Stores the active runtime contracts (WHAT interacts with WHAT), live communication topology, and critical gotchas.
> Historical architectural decisions live in [`docs/adr/decisions.md`](../docs/adr/decisions.md) and [`docs/architecture/voice-pipeline.md`](../docs/architecture/voice-pipeline.md).

---

## How to Use this File

1. **Read before planning.** Active contracts and gotchas here take precedence over unstated defaults.
2. **Keep this file lean:** Only store ACTIVE contracts, live topology, open technical debt, and critical gotchas.
3. **Architectural decisions:** Record in [`docs/adr/decisions.md`](../docs/adr/decisions.md). Do NOT accumulate historical decisions here to prevent context bloat.
4. **CRITICAL INVARIANT:** NEVER create task-specific headings (e.g., `## [Task XX.Y] Description` or `### [Task XX.Y]`) in `NOTES.md`. Task completion details live in `git log` and `.agent/ARCHIVE.md`. Architectural decisions live in `docs/adr/decisions.md`. In `NOTES.md`, maintain and update ONLY the live tables/lists of active contracts, interfaces, and topology.

---

## Active Contracts

### 1. Runtime Data & Payload Contracts

| Channel / Route / Queue | Producer | Consumer | Payload Schema / Protocol | Notes |
|---|---|---|---|---|
| `GET /health` | `offgrid-voice` | Docker / Traefik / Probe | JSON `{"status":"ok"}` | Suppress HTTP 200 access logs (`k-002`) |
| `TCP :10400` (Wyoming) | Echo / Android / Linux Satellites | `offgrid-voice` | Wyoming audio + wake/VAD events | Bi-directional PCM audio + `barge-in` |
| `WS /ws/voice` | Android Kiosk / `View Assist` | `offgrid-voice` (`Pipecat`) | Streaming PCM / JSON control frames | Phase 1/2 validation & Echo Show UI |
| `POST /v1/chat/completions` | `offgrid-voice` | `hydra-llm-router` (`fast`) | OpenAI v1 JSON + SSE + tool calls | `thinking` disabled for low-latency voice |
| `POST /send` / Redis Queue | `offgrid-voice` Tool Registry | `whatsapp-api` | `x-api-key` + Gatekeeper JSON schema | Outbound WhatsApp notifications |
| `MQTT` / HA REST | `offgrid-voice` Tool Registry | Home Assistant / Mosquitto | MQTT topics / HA Service Call JSON | Local smart home device control |

### 2. Audio & Inference Resource Boundary (`0 MB VRAM` Contention)

| Stage | Engine / Model | Compute Target | Rationale / Invariant |
|---|---|---|---|
| **VAD / Turn** | `Silero VAD` + `Smart Turn` (`pipecat-ai/smart-turn`) | CPU | Sub-10ms frame gating + semantic end-of-turn detection |
| **STT** | `whisper-large-v3-turbo` (`INT8`/`Q8_0`) or `Qwen3-ASR-1.7B-gguf` | CPU (`AVX-512` on `i5-11400`) | Zero VRAM usage; PT-BR + EN accuracy |
| **TTS** | `Piper TTS` (`pt_BR-faber-medium`) / `Kokoro-82M` | CPU | `< 100ms` PT-BR synthesis; zero VRAM usage |
| **Embeddings** | `bge-m3` / `Qwen3-Embedding-0.6B` + `sqlite-vec` | CPU (`32 GB RAM` Mini PC) | 24/7 local semantic memory without GPU dependency |
| **LLM Primary** | `local-llm-worker` (`RTX 5060 Ti 16 GB`: `Gemma-4-26B-A4B-it` / `Qwen3-14B`) | GPU via `hydra-llm-router` (`fast`) | Thinking disabled for voice turn-taking |
| **LLM Fallback** | Mini PC `i5-11400` (`Qwen3-4B` / `Gemma-3-4B`) | CPU via `hydra-llm-router` (`fast`) | Automatic failover when GPU is busy (`--parallel 1`) or offline |

### 3. LLM Gateway & Virtual Model Routing Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **API Protocol** | OpenAI v1 (`/v1/chat/completions`, `/v1/models`, `/v1/hydra/models`) | Standard JSON schema, streaming SSE, tool calling via `hydra-llm-router`; zero provider-specific SDK lock-in. |
| **Virtual Model Routing** | `fast` (default) vs. `deep` | Voice turns always target `fast` (low latency, thinking disabled); `deep` reserved for explicit async/background tasks. |
| **Network Isolation** | `hydra_shared_net` (`external: true`) | Co-located sibling containers join `hydra_shared_net` for `http://hydra-llm-router:3000/v1` (external hosts use `https://hydra-router.homelab.yegear.dev/v1`). Joining `hydra_router_internal` or `hydra_ai_net` is strictly forbidden. |
| **Client Timeout & Budget** | `LLM_TIMEOUT_SECONDS >= 180` | Minimum 180s timeout for `deep` calls; minimum `max_tokens >= 60` on test probes. |

---

## Gotchas & Pitfalls

- **0 MB VRAM Contention Invariant:** Never move STT, TTS, VAD, or embedding models onto the workstation GPU (`RTX 5060 Ti 16 GB`). All audio/memory stages stay on CPU (`i5-11400` with AVX-512 and 32 GB RAM) so `local-llm-worker` coding jobs (`--parallel 1`) and voice LLM inference never contend for VRAM.
- **Echo Hardware Bootloader Verification:** Amazon Echo Show 5/8 (`amonet 2` + LineageOS/`View Assist`) and Echo Dot 2/3 (`Firebreak`/Wyoming bridge) require specific hardware/bootloader revisions. Always verify board/bootloader revision before hardware acquisition (Phase 3).
- **Healthcheck Probe Log Suppression:** Suppress HTTP 200 `/health` access logs at the application or proxy layer to prevent VictoriaLogs telemetry flooding.
- **LLM Gateway Reasoning Tokens & Timeouts:** When calling thinking-enabled models via `deep`, set client HTTP timeouts `>= 180` seconds and `max_tokens >= 60` on smoke probes. For real-time voice turns, use `fast` with thinking disabled.

---

## Deliberate Technical Debt

| Debt | Rationale | Revisit When |
|---|---|---|
| Android Kiosk / Wyoming Linux client as Phase 1/2 validation client | Decouples core pipeline delivery from Echo hardware acquisition and jailbreak risk | Phase 3 (Hardware Acquisition & Jailbreak) |
