# Discovered Endpoints and Integration Contracts

> Source of truth. Without a cataloged route here + minimal cURL, no production client code may be written.
> Anatomy and examples: [`.agent/skills/reverse-engineering/SKILL.md`](./skills/reverse-engineering/SKILL.md).

---

## 1. Global Context

- **Target System Name:** […]
- **Base Host:** `[https://…]`
- **Auth / Session Strategy:** [cookie, CSRF, lifetime, session expiration signal]
- **Global Headers / Content-Type:** […]

---

## 2. Route Matrix

| Method | Endpoint / Action | Purpose | Status | Auth? | Last Verified |
| :---: | :--- | :--- | :---: | :---: | :---: |
| | | | | | |

*(Status: `Discovered` $\rightarrow$ `Mapping` $\rightarrow$ `Validated` $\rightarrow$ `Deprecated`)*

---

## 3. Route Card (copy per route)

### 📌 [METHOD] `path`

- **Description:**
- **Headers:**
- **Parameters:** field / type / location (query/body/path) / required
- **Expected Success / Error Codes:**
- **Minimal cURL:**
  ```bash
  curl -s -X METHOD "$TARGET_BASE_URL/path" \
    -b "SESSION=$TARGET_SESSION_COOKIE" \
    -d "..."
  ```
- **Fixture:** `tests/fixtures/…`
- **Gotchas / Quirks:**
