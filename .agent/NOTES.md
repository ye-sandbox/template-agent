# NOTES.md — Long-Term Memory and Target System Invariants

> 🧠 **Long-Term Memory:** Record integration decisions, target system quirks not obvious from code, and infrastructure constraints here.

---

## 1. Architecture and Tooling Decisions
- **HTTP Client Choice:** [e.g. httpx with connection pooling and HTTP/2 support]
- **HTML/DOM Parser Strategy:** [e.g. selectolax / BeautifulSoup for mixed encoding HTML]
- **Session Lifecycle Management:** [e.g. automatic refresh via interceptor on 302 login redirect]

---

## 2. Invariants and Target System Quirks
- [e.g.: The portal drops connections that do not send a Chrome-like `User-Agent`.]
- [e.g.: Numerical IDs return 500 if sent with leading zeros.]
- [e.g.: System enforces a mandatory 250ms minimum delay between sequential requests.]

---

## 3. Technical Discoveries Log
*(Add short, dated entries as behaviors are identified)*

- **2026-09-04:** Initialized blackbox integration repository.
