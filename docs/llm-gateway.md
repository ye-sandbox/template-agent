---
author_type: agent-assisted
author: Architecture Team
reviewed_by: Human Lead
date: 2026-11-07
status: accepted
type: architectural-specification
---

# LLM Gateway & Virtual Model Routing Specification

Canonical specification for consumer applications integrating with the central LLM Gateway (Hydra AI / New API) via OpenAI v1 compatible protocols, resilient virtual model routing, Docker network boundaries, client timeout invariants, and token tier management.

---

## 1. Overview & Core Philosophy

In Agent-Driven Development (ADD) and homelab microservice ecosystems, consumer applications must never hardcode proprietary upstream LLM providers (e.g., Google AI Studio, OpenAI, Anthropic, Groq) or brittle provider-specific model strings (`gemini-2.5-flash`, `gpt-4o-2024-08-06`). Upstream model lifecycles, deprecation schedules, API version shifts, and quota pool exhaustion create systemic failure points across distributed repositories.

The central LLM Gateway acts as a reverse proxy, routing fabric, quota arbiter, and compatibility adapter:
1. **OpenAI v1 Standard Interface:** Exposes standard `/v1/chat/completions` and `/v1/models` endpoints supporting JSON schema mode, streaming SSE (`text/event-stream`), tool/function calling, and multi-turn conversations.
2. **Virtual Model Abstraction:** Maps semantic routing tags (`free-fast`, `free-deep`) to optimal upstream providers dynamically, isolating consumer code from upstream API deprecations.
3. **Hermetic Docker Topology:** Restricts internal inter-container traffic to dedicated bridge networks (`hydra_shared_net`), isolating stateful backend tiers (Redis, database).
4. **Deterministic Token Tiers:** Enforces quota budgets and token ceilings per application tier to protect upstream shared budgets.

---

## 2. Virtual Model Routing Hierarchy

Consumer applications must route inference requests using semantic virtual model aliases rather than explicit provider models:

| Virtual Model | Primary Workload Profile | Upstream Provider Target (Dynamic) | Context Window | Latency Profile |
| :--- | :--- | :--- | :--- | :--- |
| **`free-fast`** | Micro-extractions, intent classification, guardrails, fast tool dispatch, semantic classification, test assertions. | Google AI Studio (`gemini-2.5-flash`), Groq (`llama-3.3-70b-versatile`) | Up to 1M tokens (target call: $\le 10\text{k}$) | Ultra-low latency ($< 1.5\text{s}$) |
| **`free-deep`** | Deep reasoning, architectural synthesis, long-context document ingestion, code generation, multi-file diff auditing. | Google AI Studio (`gemini-3.8-flash`, `gemini-3.6-flash`, thinking-enabled models) | Up to 1M tokens | High throughput, deep reasoning budget |

### Routing Agility Invariant
- **Zero Consumer Code Drift:** If an upstream model is deprecated or experiences a regional outage, gateway administrators update channel routing in the gateway backend. Consumer applications experience zero downtime and require zero code refactoring or redeployments.
- **Header Overrides:** Internal testing frameworks may supply model overrides via standard request parameters only when testing experimental candidate channels.

---

## 3. Network Topologies & Access Contracts

Consumer applications access the gateway across three distinct deployment topologies:

```mermaid
flowchart TD
    subgraph CoreHost["Host / Core Infrastructure"]
        subgraph HydraStack["Hydra AI Stack"]
            Gateway["hydra-ai-gateway:3000"]
            Redis[("Redis Cache")]
            Gateway -.->|hydra_ai_net (isolated)| Redis
        end

        subgraph SiblingApps["Sibling Microservices"]
            App1["Consumer Container"]
            App2["Background Worker"]
        end

        Traefik["Traefik v3 Proxy"]
    end

    DevMachine["Dev Workstation / CLI"]
    ExternalClient["External Client"]

    App1 -->|hydra_shared_net:3000| Gateway
    App2 -->|hydra_shared_net:3000| Gateway
    Traefik -->|proxy_public:3000| Gateway

    DevMachine -->|HTTPS / Bearer Auth| Traefik
    ExternalClient -->|HTTPS / Bearer Auth| Traefik
    DevMachine -.->|Loopback 127.0.0.1:3000| Gateway
```

### Topology Matrix

| Topology | Target Endpoint URL | Network / Interface | Routing & Authentication Contract |
| :--- | :--- | :--- | :--- |
| **1. Sibling Container (Same Host)** | `http://hydra-ai-gateway:3000/v1` | `hydra_shared_net` (`external: true`) | Direct internal Docker DNS resolution; zero TLS/NAT hairpinning. Redis remains isolated on `hydra_ai_net`. |
| **2. Remote Host / Dev Workstation** | `https://hydra.homelab.yegear.dev/v1` | Traefik v3 (`proxy_public`) | TLS terminated by Traefik with Cloudflare DNS challenge. `/v1` routes bypass Authelia interactive SSO and authenticate via `Authorization: Bearer <token>`. |
| **3. Local Host Script / CLI** | `http://127.0.0.1:3000/v1` | Loopback (`127.0.0.1`) | Bound to host loopback interface (`GATEWAY_BIND_IP=127.0.0.1`). |

### Network Boundary Invariants
- `[P0]` **FORBIDDEN NETWORK ATTACHMENT:** Consumer applications MUST NOT attach to `hydra_ai_net`. The `hydra_ai_net` bridge is strictly private to the gateway and its Redis instance.
- `[P1]` **SIBLING ATTACHMENT:** Consumer applications running in Docker Compose on the core host MUST join the external bridge network `hydra_shared_net`.

---

## 4. Environment Variables & Client Invariants

### Canonical Environment Schema
Every template starter and consumer application repository MUST declare the following environment variables in `.env.example`:

```dotenv
# ==============================================================================
# LLM Gateway Integration (Hydra AI - OpenAI v1 Compatible)
# Sibling Container: http://hydra-ai-gateway:3000/v1
# Remote Traefik HTTPS: https://hydra.homelab.yegear.dev/v1
# Localhost CLI: http://127.0.0.1:3000/v1
# ==============================================================================
LLM_BASE_URL=http://hydra-ai-gateway:3000/v1
LLM_API_KEY=sk-replace-with-hydra-tier-token
LLM_MODEL_FAST=free-fast
LLM_MODEL_DEEP=free-deep
LLM_TIMEOUT_SECONDS=180
```

### Mandatory Client Invariants

1. **Client Timeout Invariant ($\ge 180\text{s}$):**
   Calls to `free-deep` ingest extensive context (up to 1M tokens) and invoke thinking/reasoning mechanisms. Client SDKs MUST configure an explicit timeout of at least `180` seconds (`httpx.Timeout(180.0, connect=10.0)` or `timeout: 180000`). Relying on default 15-30s HTTP client timeouts causes premature aborts on complex prompts.

2. **Reasoning Token Headroom Invariant (`max_tokens >= 60`):**
   Upstream models supporting chain-of-thought (e.g. Gemini thinking models) generate internal reasoning tokens before emitting completion content. Test probes, smoke scripts, and low-latency calls MUST NOT configure microscopic limits like `max_tokens: 5` or `max_tokens: 10`. A minimum `max_tokens >= 60` (or leaving `max_tokens` unset for open generation) is required to prevent empty response bodies (`content: ""`) where the reasoning phase consumes the entire token allocation.

3. **Stream Buffer Handling:**
   When using streaming completions (`stream=True`), clients must handle chunk intervals without dropping connection, buffering delta content until `finish_reason` is received.

---

## 5. Client Token Tier Taxonomy

Client application tokens issued by the gateway fall into three distinct tiers:

| Tier | Token Identifier | Target Quota Budget | Use Cases & Consumer Scope |
| :---: | :--- | :---: | :--- |
| **Tier 1** | `hydra-token-production-<app>` | $5{,}000{,}000$ units (~$10 equiv) | Critical background production pipelines (e.g., `whatsapp-digest`, event listeners). |
| **Tier 2** | `hydra-token-dev-<app>` | $1{,}000{,}000$ units (~$2 equiv) | Developer workstations, interactive sessions, exploratory scripts, sandbox worktrees. |
| **Tier 3** | `hydra-client-default` | Unlimited (`-1`) | Internal health probes, CI test assertions, automated scaffolding smoke tests. |

---

## 6. Implementation Patterns & SDK Recipes

### Pattern 1: Docker Compose Sibling Wiring (`compose.yaml`)

```yaml
services:
  app:
    image: ghcr.io/ye-sandbox/my-app:1.0.0
    restart: unless-stopped
    environment:
      - LLM_BASE_URL=${LLM_BASE_URL:-http://hydra-ai-gateway:3000/v1}
      - LLM_API_KEY=${LLM_API_KEY}
      - LLM_MODEL_FAST=${LLM_MODEL_FAST:-free-fast}
      - LLM_MODEL_DEEP=${LLM_MODEL_DEEP:-free-deep}
      - LLM_TIMEOUT_SECONDS=${LLM_TIMEOUT_SECONDS:-180}
    networks:
      - default
      - hydra_shared_net

networks:
  default:
  hydra_shared_net:
    name: hydra_shared_net
    external: true
```

### Pattern 2: Python Async Client (`openai >= 1.0`)

```python
import os
import httpx
from openai import AsyncOpenAI

# INVARIANT: Timeout >= 180s to accommodate long context and reasoning phases
llm_client = AsyncOpenAI(
    base_url=os.getenv("LLM_BASE_URL", "http://hydra-ai-gateway:3000/v1"),
    api_key=os.environ["LLM_API_KEY"],
    timeout=httpx.Timeout(float(os.getenv("LLM_TIMEOUT_SECONDS", "180.0")), connect=10.0),
    max_retries=2,
)

async def fast_intent_classify(prompt: str) -> str:
    """Low-latency classification using free-fast."""
    response = await llm_client.chat.completions.create(
        model=os.getenv("LLM_MODEL_FAST", "free-fast"),
        messages=[{"role": "user", "content": prompt}],
        temperature=0.1,
        # INVARIANT: max_tokens >= 60 to prevent thinking tokens from starving completion
        max_tokens=128,
    )
    return response.choices[0].message.content or ""

async def deep_reasoning_synthesis(context_prompt: str) -> str:
    """High-context reasoning using free-deep."""
    response = await llm_client.chat.completions.create(
        model=os.getenv("LLM_MODEL_DEEP", "free-deep"),
        messages=[{"role": "user", "content": context_prompt}],
        temperature=0.3,
    )
    return response.choices[0].message.content or ""
```

### Pattern 3: TypeScript / Node.js Client (`openai`)

```typescript
import OpenAI from "openai";

// INVARIANT: Explicit timeout in milliseconds to prevent default client cutoff
export const llm = new OpenAI({
  baseURL: process.env.LLM_BASE_URL ?? "http://hydra-ai-gateway:3000/v1",
  apiKey: process.env.LLM_API_KEY,
  timeout: Number(process.env.LLM_TIMEOUT_SECONDS ?? 180) * 1000,
  maxRetries: 2,
});

export async function fastIntentClassify(prompt: string): Promise<string> {
  const completion = await llm.chat.completions.create({
    model: process.env.LLM_MODEL_FAST ?? "free-fast",
    messages: [{ role: "user", content: prompt }],
    temperature: 0.1,
    max_tokens: 128,
  });
  return completion.choices[0]?.message?.content ?? "";
}

export async function deepReasoningSynthesis(context: string): Promise<string> {
  const completion = await llm.chat.completions.create({
    model: process.env.LLM_MODEL_DEEP ?? "free-deep",
    messages: [{ role: "user", content: context }],
    temperature: 0.3,
  });
  return completion.choices[0]?.message?.content ?? "";
}
```

---

## 7. Contrast Pairs & Anti-Patterns

### Model Identifier Binding
```python
# BAD: Direct upstream provider binding and hardcoded model string
client = AsyncOpenAI(
    base_url="https://generativelanguage.googleapis.com/v1beta/openai",
    api_key="AIzaSy...",
)
# BREAKS: Upstream model deprecation requires source code refactoring
resp = await client.chat.completions.create(
    model="gemini-2.5-flash",
    messages=[...],
)

# GOOD: Gateway endpoint with resilient virtual model routing
client = AsyncOpenAI(
    base_url=os.getenv("LLM_BASE_URL", "http://hydra-ai-gateway:3000/v1"),
    api_key=os.environ["LLM_API_KEY"],
    timeout=180.0,
)
resp = await client.chat.completions.create(
    model=os.getenv("LLM_MODEL_FAST", "free-fast"),
    messages=[...],
)
```

### Docker Network Binding
```yaml
# BAD: Attaching application to the internal Redis network
services:
  app:
    networks:
      - hydra_ai_net  # CRITICAL SECURITY RISK: Exposes internal Redis database

# GOOD: Attaching application strictly to hydra_shared_net bridge
services:
  app:
    networks:
      - default
      - hydra_shared_net
```

### Timeout & Token Budget
```python
# BAD: 10s timeout and 5 token cap causes failure with thinking models
response = await client.chat.completions.create(
    model="free-deep",
    max_tokens=5,  # BREAKS: Reasoning consumes all tokens; content is empty
    timeout=10.0,  # BREAKS: ReadTimeout on long context
)

# GOOD: Adequate timeout and reasoning token headroom
response = await client.chat.completions.create(
    model=os.getenv("LLM_MODEL_DEEP", "free-deep"),
    max_tokens=256,
)
```

---

## 8. Definition of Done & Verification Protocol

Before declaring an application compliant with the LLM Gateway specification, verify:

1. **Zero Upstream Provider Coupling:**
   Execute static analysis on source files to ensure no hardcoded upstream endpoints or proprietary model names exist:
   ```bash
   grep -rnE "(gemini-[0-9]|gpt-4o|claude-3|generativelanguage\.googleapis|api\.openai\.com|api\.groq\.com)" src/
   ```
   *Expected result: Zero occurrences.*

2. **Environment Variable Hygiene:**
   Ensure `.env.example` contains canonical variables (`LLM_BASE_URL`, `LLM_API_KEY`, `LLM_MODEL_FAST=free-fast`, `LLM_MODEL_DEEP=free-deep`, `LLM_TIMEOUT_SECONDS=180`).

3. **Network Boundary Audit:**
   Ensure `compose.yaml` (if present) references `hydra_shared_net` as `external: true` and contains zero references to `hydra_ai_net`.

4. **Gateway Smoke Probe Assertion:**
   Ensure gateway health and virtual model availability can be verified via standard CLI probes:
   ```bash
   curl -sf "${LLM_BASE_URL}/models" -H "Authorization: Bearer ${LLM_API_KEY}" | grep -q "free-fast"
   ```
