---
id: "k-001"
title: "Detecting Soft HTTP 200 Session Expiry in Legacy Portals and Undocumented APIs"
date: 2026-10-19
tags:
  - "reverse-engineering"
  - "auth"
  - "session"
  - "http"
  - "scraping"
severity: "high"
affected_components:
  - ".agent/ENDPOINTS.md"
  - "src/client.js"
  - "tests/fixtures/"
symptoms:
  - "HTTP 200 OK returned on expired session instead of 401 or 403"
  - "JSONDecodeError: Expecting value: line 1 column 1 (char 0)"
  - "Unexpected token '<', \"<!DOCTYPE \"... is not valid JSON"
  - "Silent failure parsing empty DOM elements after session expiration"
---

# [k-001] Detecting Soft HTTP 200 Session Expiry in Legacy Portals and Undocumented APIs

## Problem / Symptom

When integrating with or scraping undocumented enterprise legacy backends (e.g., PHP monoliths, ASP.NET WebForms, Java Spring/Struts), session expiration and authentication failures rarely return standard HTTP status codes (`401 Unauthorized` or `403 Forbidden`).

Instead, the server responds with a **Soft 200 OK** returning HTML containing an embedded login form, an inline JavaScript redirection script (e.g., `<script>window.location='/login.php'</script>`), or a modal error dialog.

If the HTTP client or scraper only evaluates `response.ok` or `response.status === 200`, it assumes the request succeeded and passes the HTML body directly to JSON decoders or DOM entity extractors. This results in obscure downstream failures:

```text
SyntaxError: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
    at JSON.parse (<anonymous>)
    at parseApiResponse (/app/src/client.js:42:19)
    at processTicksAndRejections (node:internal/process/task_queues:95:5)
```

In Python-based clients:
```text
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

Or worse, headless scrapers query DOM selectors that evaluate to `null` without throwing errors, causing silent data corruption.

## Approved Solution

Always intercept and validate session validity at the HTTP transport / client layer before attempting to deserialize responses or extract data:

1. **Implement Transport-Level Session Validation:** Inspect response `Content-Type` headers and probe for dead-session HTML signatures:

```javascript
// src/client.js
export class SessionExpiredError extends Error {
  constructor(message = 'Session token expired or invalidated by target portal') {
    super(message);
    this.name = 'SessionExpiredError';
  }
}

export function assertActiveSession(response, responseText) {
  const contentType = response.headers.get('content-type') || '';

  // Case 1: Expected JSON but received HTML login page
  const isHtml = contentType.includes('text/html');
  const hasLoginForm = /<input[^>]+type=["']password["']/i.test(responseText) ||
                       /name=["'](infra_hash|csrf_token|__VIEWSTATE)["']/i.test(responseText);
  const hasRedirectScript = /window\.location(\.href)?\s*=\s*['"][^'"]*login/i.test(responseText);

  if (isHtml && (hasLoginForm || hasRedirectScript)) {
    throw new SessionExpiredError();
  }

  // Case 2: Soft 200 containing JSON error wrapper
  if (contentType.includes('application/json')) {
    try {
      const data = JSON.parse(responseText);
      if (data.status === 'expired' || data.error_code === 'AUTH_EXPIRED') {
        throw new SessionExpiredError(data.message || 'API session expired');
      }
    } catch (err) {
      if (err instanceof SessionExpiredError) throw err;
      // Fall through for generic JSON decode error handling
    }
  }
}
```

2. **Catalog Expiration Signatures in `.agent/ENDPOINTS.md`:** Under each route card, explicitly document the dead session signature (e.g., `Dead Session: 200 with <input id="txtUsuario">` or `Dead Session: 302 redirect`).

3. **Separate Auth Renewal from Generic Retries:** Catch `SessionExpiredError` specifically to trigger automated session renegotiation or cookie re-acquisition.

**Root Cause:** Legacy enterprise frameworks often handle session expiration via front-controller filters that redirect browser navigation to a login view template without setting appropriate non-200 HTTP response codes.

## What NEVER to Do

- ❌ **Anti-Pattern:** Auto-retrying the exact same HTTP request with the same expired cookies when receiving a `JSONDecodeError` or empty DOM nodes.
  - *Why:* Retrying without acquiring a new session cookie triggers rapid repeated requests, risking account lockout or IP rate-limiting.
- ❌ **Anti-Pattern:** Silently falling back to empty arrays or default objects (`return []`) when expected JSON properties are undefined in an HTML payload.
  - *Why:* Masking authentication failures as "empty results" leads to silent data loss and false reconciliation reports.
- ❌ **Anti-Pattern:** Inspecting session health only inside high-level business functions rather than the low-level HTTP transport client.
  - *Why:* Fragmented checks lead to inconsistent behavior and duplicated regex signatures across multiple scrapers and endpoints.

## Verification

Create and execute a test fixture replicating the portal's dead-session HTML response:

```bash
# Verify that the HTTP client raises SessionExpiredError when presented with dead-session HTML
pytest tests/test_session.py  # or: npm test
```

## References
- [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [Reverse Engineering Skill Protocol: Step 2 & Step 6](../skills/reverse-engineering/SKILL.md)
