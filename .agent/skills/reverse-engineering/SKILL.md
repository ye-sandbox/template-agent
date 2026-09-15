---
name: reverse-engineering
description: Methodology and standard operating protocol for dissecting, validating, documenting, and integrating undocumented legacy APIs and web portals (Blackbox Reverse Engineering).
---

# Undocumented API & Portal Reverse Engineering (`reverse-engineering`)

This skill defines the standard operating procedure for AI agents integrating with undocumented systems (e.g. monolithic ERPs, state/enterprise portals, closed legacy backends).

---

## 🧭 The 6-Stage Lifecycle

```text
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  1. Traffic     │ ──> │ 2. Session &     │ ──> │ 3. cURL          │
│     Capture     │     │    Auth Isolation│     │    Minimization  │
└─────────────────┘     └──────────────────┘     └──────────────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ 6. Typed HTTP   │ <── │ 5. Sanitized     │ <── │ 4. Catalog in    │
│    Client       │     │    Test Fixtures │     │    ENDPOINTS.md  │
└─────────────────┘     └──────────────────┘     └──────────────────┘
```

---

## Step 1: Traffic Capture & Inspection

1. **Open DevTools (Network tab) or proxy (mitmproxy):**
   - Enable "Preserve log" to trace cross-page redirects.
   - Execute the action manually or via automation.
2. **Identify the critical request:**
   - Filter by `Fetch/XHR` or `Doc` (for legacy `POST` forms).
   - Locate the exact call carrying domain data.
3. **Export the request:**
   - Copy as cURL (`Copy as cURL (bash)`).
   - **NEVER** commit HAR files containing live session tokens to git.

---

## Step 2: Session & Auth Isolation

Legacy systems rarely rely on static Bearer tokens. Identify:
1. **Session Cookies:** Which cookies are strictly required? (Test removing cookies one by one in cURL).
2. **CSRF / Anti-Forgery Tokens:**
   - Check for tokens like `infra_hash`, `csrf_token`, `__VIEWSTATE`, `authenticity_token`.
   - Locate which prior response delivered the token (usually `<input type="hidden">` fields).
3. **Session Lifecycle:**
   - What is the session TTL?
   - How does the server signal expired sessions? (302 redirect to login, or 200 with error HTML?).

---

## Step 3: Minimization & Validation via cURL

Before writing any application code:
1. **Eliminate Noise:**
   - Remove browser-specific clutter (`Sec-Ch-Ua`, `Accept-Language`, `Sec-Fetch-*`).
   - Retain only essentials (`Cookie`, `Content-Type`, `User-Agent`, `Referer` if enforced).
2. **Validate in Terminal:**
   ```bash
   curl -s -i -X POST "URL" -H "..." -d "..."
   ```
   - Ensure the call succeeds repeatedly without triggering rate limits.

---

## Step 4: Catalog in `.agent/ENDPOINTS.md`

Immediately after terminal validation:
1. Register the route in the **Route Matrix**.
2. Add a **Route Card** containing:
   - Method and exact path.
   - Required headers.
   - Mandatory and optional query/body parameters.
   - Tested reproducible minimal cURL command.
   - Quirks/gotchas (e.g. ISO-8859-1 encoding, hidden fields).

### Canonical Example

```markdown
### 📌 [POST] `controlador.php?acao=procedimento_trabalhar`

- **Headers:** `Cookie: SEI_SESSION=<session-token>` · `Content-Type: application/x-www-form-urlencoded`
- **Body:** `id_procedimento` (int) · `infra_hash` (CSRF from prior page)
- **Success 200:** HTML `ISO-8859-1`; `#divArvoreHtml [data-id-documento]`; `#txtNumeroProcesso`
- **Dead Session:** 302 or 200 with `<input id="txtUsuario">`
- **cURL:**
  ```bash
  curl -s -X POST "$TARGET_BASE_URL/controlador.php?acao=procedimento_trabalhar" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -b "SEI_SESSION=$TARGET_SESSION_COOKIE" \
    -d "id_procedimento=1234567&infra_hash=$TARGET_CSRF_HASH"
  ```
- **Gotchas:** ISO-8859-1 charset; empty `id_procedimento` returns home dashboard without HTTP error.
```

---

## Step 5: Author Sanitized Test Fixtures

**Golden Rule:** Automated tests must never hit live production servers in continuous CI runs.

1. Save the response body from Step 3 into `tests/fixtures/<target>_<action>_success.<json|html>`.
2. **Sanitize Data:** Replace personal identifiable information (PII), names, IDs, and tokens with synthetic placeholders.
3. Save typical failure scenarios (e.g., `tests/fixtures/<target>_session_expired.html`).

---

## Step 6: Typed HTTP Client Implementation

1. **Strict Typing:** Author schemas (Pydantic / Zod / Dataclasses) for input payloads and parsed responses.
2. **Resilience & Retry:**
   - Retry transient network failures only (502, 503, 504, 429, `TimeoutException`).
   - **NEVER** auto-retry auth failures (401/403) without triggering session renewal.
3. **Session Expiry Detection:**
   - Check for login form markers in returned HTML prior to running data parsers.
   - Raise explicit `SessionExpiredError` on expiration to trigger automated re-login.
4. **Concurrency & Rate Limits:**
   - Enforce pacing (`asyncio.Semaphore` or token bucket) to avoid IP bans.
