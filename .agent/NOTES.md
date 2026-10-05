# NOTES.md — Active Contracts and Target Invariants

> Stores active integration contracts, session invariants, target quirks, and multi-agent topology.
> Historical architectural decisions live in [`docs/adr/decisions.md`](../docs/adr/decisions.md).
> Endpoint payload specifications live in [`.agent/ENDPOINTS.md`](ENDPOINTS.md).

---

## How to Use this File

1. **Read before planning.** Active session policies and target quirks prevent anti-bot lockouts.
2. **Keep this file lean:** Only store active session states, integration contracts, and critical gotchas.
3. **Architectural decisions:** Record in [`docs/adr/decisions.md`](../docs/adr/decisions.md).

---

## Active Contracts & Multi-Agent Topology

### 1. Multi-Agent Topology & Ensemble Contract (Dev Trinity Sentinel)

When operating under Maestri / Antigravity orchestration:
- **Planner:** Manages `.agent/TASK.md` and dispatches execution.
- **Developer:** Executes probe/client code under `aether-guard wrap`.
- **Auditor:** Verifies mock isolation and zero hardcoded credentials against DoD.
- **Aether Sentinel:** Live supervisor terminal monitoring command security and rate limits.

### 2. Active Session & Integration Contracts

- **HTTP Client Baseline:** [e.g. httpx with connection pooling and HTTP/2 support]
- **HTML/DOM Parser:** [e.g. selectolax / BeautifulSoup for mixed encoding HTML]
- **Session Lifecycle:** [e.g. automatic refresh via interceptor on 302 login redirect]

---

## Target System Invariants & Discovered Quirks

- [e.g.: The portal drops connections that do not send a Chrome-like `User-Agent`.]
- [e.g.: Numerical IDs return 500 if sent with leading zeros.]
- [e.g.: System enforces a mandatory 250ms minimum delay between sequential requests.]
