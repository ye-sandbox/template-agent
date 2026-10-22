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

## Active Contracts

### 1. Active Session & Integration Contracts

- **HTTP Client Baseline:** [e.g. httpx with connection pooling and HTTP/2 support]
- **HTML/DOM Parser:** [e.g. selectolax / BeautifulSoup for mixed encoding HTML]
- **Session Lifecycle:** [e.g. automatic refresh via interceptor on 302 login redirect]

### 2. Multi-Agent Collaboration Roles (Optional)

> For reverse engineering or scraper operations utilizing multiple AI agents. If single-agent, leave as default.

- **Planner:** Manages target priorities in `.agent/TASK.md` and defines extraction scope.
- **Investigator (Developer):** Implements client probes, parsers, and replay scripts strictly within task scope.
- **Auditor:** Verifies mock isolation, rate limiting guardrails, and zero hardcoded credentials against DoD.

---

## Target System Invariants & Discovered Quirks

- [e.g.: The portal drops connections that do not send a Chrome-like `User-Agent`.]
- [e.g.: Numerical IDs return 500 if sent with leading zeros.]
- [e.g.: System enforces a mandatory 250ms minimum delay between sequential requests.]
