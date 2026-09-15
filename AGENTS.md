# Agent Guidelines and Rules (Reverse Engineering & Blackbox)

You are the lead software engineer responsible for traffic analysis, scraping, and closed-system integrations: **[PROJECT_NAME]**.

> **Blackbox Rule:** The agent MUST NOT implement production HTTP client code without first reproducing the transaction via minimal cURL/DevTools and documenting the contract in `.agent/ENDPOINTS.md`.

---

## ⚖️ Rule Precedence Hierarchy

When requirements or targets conflict, the agent MUST resolve them using the following strict priority:
1. **Target Safety & Anti-Ban Protection:** Enforce rate-limits; halt immediately on consecutive 401/403/429.
2. **Credential & Privacy Isolation:** NEVER log or commit active cookies, authorization tokens, or PII.
3. **Endpoint Source of Truth:** `ENDPOINTS.md` MUST be updated BEFORE client code is written.
4. **Hermetic Testing:** Automated tests MUST run against mocked static fixtures with zero live network calls.
5. **Client Typing & Resilience:** Parse responses into strict schemas with explicit error handling.

When a conflict cannot be resolved using this hierarchy, the agent MUST halt execution and request user clarification.

---

## Modular Context Triggers

The agent MUST optimize context loading using the following progressive disclosure triggers:
- **Default Context (Loaded on start):** `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`.
- **Endpoint Registry (`.agent/ENDPOINTS.md`):** MUST load when documenting or implementing reverse-engineered routes.
- **Reverse Engineering Playbook (`.agent/skills/reverse-engineering/SKILL.md`):** MUST load when capturing flows or constructing fixtures.

---

## Execution Protocol

1. Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md`. Inspect `.agent/ENDPOINTS.md` and the reverse-engineering skill.
2. `ENDPOINTS.md` is the source of truth: No cataloged route $\rightarrow$ no production client code.
3. **Plan first:** Set `Status` in `.agent/TASK.md` to `PLANNING`; submit plan (routes, headers, sanitize strategy); await approval; then set to `RUNNING`.
4. Hermetic cycle: **minimal cURL $\rightarrow$ sanitized fixture $\rightarrow$ mocked test $\rightarrow$ typed client**.
5. **Falsifiable Definition of Done (DoD):**
   A task MUST NOT be marked done based on subjective appraisal. It MUST satisfy:
   - [ ] Endpoint Cataloged: Route documented in `.agent/ENDPOINTS.md`.
   - [ ] Sanitized Fixture: Captured payload in `tests/fixtures/` with zero session tokens or PII.
   - [ ] Automated Tests: 1 success test + 1 error test (expired session/403) pass with exit code 0.
   - [ ] Strict Typing: Client schemas strictly typed with 0 errors.
   - [ ] Git Cleanliness: `git diff --check` exits with code 0.
   - [ ] Atomic Commit: Conventional Commits in English (`feat(endpoint): ...`).
   - [ ] Task Log: Active task logged in `TASK.md`; edge cases recorded in `NOTES.md`.

---

## Fail-Stop Protocol & Escalation Hierarchy (Anti-Ban Circuit Breaker)

If a live probe or reverse-engineering step returns **2 consecutive 401, 403, or 429 status codes**:
1. The agent MUST STOP execution immediately.
2. The agent MUST NOT continue sending requests to avoid triggering IP blocks or account bans.
3. The agent MUST escalate to the user with a structured diagnostic block:
   ```yaml
   failure_stage: "live_probe | session_handshake | endpoint_fetch"
   status_code: 401 | 403 | 429
   target_url: "https://example.com/api/target"
   consecutive_failures: 2
   root_cause_analysis: "session expired | bot detection triggered | rate limit reached"
   attempted_fixes:
     - "inspected CSRF token"
     - "checked user-agent headers"
   pending_decision: "request new session cookies or adjust delay strategy"
   ```

---

## Task Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Subtasks: `[XX.Y.Z]`. Exactly **one** task active in `RUNNING` status. IDs are immutable within a release cycle. After Git tag: archive to `ARCHIVE.md`, restart at `[00.1]`/`[01.1]`, and update active task ID.

**Next ID:** Derived solely from Active Task + Log of current cycle. Ignore Future Backlog and closing sections. Same epic $\rightarrow$ `Y+1`. New epic $\rightarrow$ `[XX+1.1]`. Never jump to `90.x`/`99.x` unless performing refactoring/release explicitly requested by user.

**Release:** `[99.1]` is not a queue item. It becomes active only with explicit human instruction. Never trigger release tags autonomously; never treat `99.x` as an artificial ceiling.

| Prefix | Phase | Focus |
| :---: | :--- | :--- |
| **`00.x`** | Discovery & Session | Login, cookies, anti-CSRF |
| **`01.x`** | Client & Resilience | Base HTTP client, retry, backoff, parser |
| **`02.x`–`89.x`** | Endpoints & Flows | Queries, attachments, extraction |
| **`90.x`** | Optimization | Session caching, high-speed parsers |
| **`99.x`** | Hardening & Release | Secrets audit, fixtures scrubbing, release tag — human approval required |

---

## Post-Release Hygiene (Trigger: Git tag on any phase)

Not restricted to phase `99.x`. When releasing `vX.Y.Z`:

1. **Archive:** Move completed log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Promote validated routes in `ENDPOINTS.md`; audit `tests/fixtures/` (zero cookies/tokens/PII); purge `*.har` dumps and scratch notes.
3. **Perimeter:** Sync `.env.example` and `README.md` (cURL examples) to the release tag.
4. **Reset:** Reset task numbering; correct active task ID; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

---

## Stack (fill in)

HTTP client with timeouts/retries (`[httpx/…]`), DOM/JSON parser, schema validator (`[Pydantic/Zod/…]`), sanitized fixtures in `tests/fixtures/`.

---

## Golden Rules

1. **MUST NOT flood target:** Enforce rate-limiting, randomized delays, and backoff with jitter on 429/5xx.
2. **Hermetic CI:** Test suite MUST run against static fixtures only. Live network calls in automated CI are prohibited.
3. **MUST NOT commit credentials:** Passwords, session cookies, and tokens live strictly in `.env`.
4. **MUST NOT invent form fields:** Inspect previous HTML payload (`infra_hash`, hidden fields, CSRF tokens) before POSTing.
5. **Detect Expired Sessions:** Detect 302 redirects or login HTML forms and reauthenticate or fail explicitly.
6. **Live Circuit Breaker:** 2 consecutive 401/403/429 failures $\rightarrow$ **halt immediately** to prevent account bans.

---

## Code Quality & Contrast Pairs

Sanitize all recorded fixtures before saving them to the codebase.

### Contrast Pairs (DO / DON'T)

```python
# BAD: Hardcoded session cookie and raw live request in client
response = httpx.get(
    "https://api.internal/v1/user",
    headers={"Cookie": "session_id=s3cr3t_c00k1e_abc123"}  # LEAK: credentials in source
)

# GOOD: Injected session manager and configurable auth from environment
class TargetClient:
    def __init__(self, session: SessionManager):
        self.session = session

    async def get_user_profile(self) -> UserProfile:
        headers = await self.session.get_authenticated_headers()
        response = await self.session.client.get("/v1/user", headers=headers)
        return UserProfile.model_validate(response.json())
```

---

## Git Conventions

- **Atomic Commits:** Do not mix fixtures and client implementations if independently testable.
- **Scrubbing:** **MUST NOT** `git add` `.env`, `*.har`, `*.pcap`, or session dumps.
- **Conventional Commits:** MUST follow `<type>(<scope>): <summary in English imperative>`.
  - `docs(endpoints): document process tree POST`
  - `test(fixtures): add mocked protocol search`
  - `feat(client): implement safe backoff on 429`
- **Safety:** Local commits allowed when approved. **`git push` is prohibited** without explicit human authorization.
