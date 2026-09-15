# INVARIANTS.md — System Invariants and Untouchable Rules

> 🧱 **Chesterton's Fence Principle:**
> *"Never remove a rule, filter, or unusual piece of code until you understand why it was put there."*
>
> This file is the source of truth for **legacy system behaviors, quirks, and rigid contracts** that may appear redundant, suboptimal, or ugly at first glance, but **MUST NOT BE CHANGED** without explicit user consent.

---

## How to Use this File (for the Agent)

1. **Check before any change:** Always consult this file before planning changes to models, routes, or queries.
2. **Document implicit rules upon discovery:** When investigating bugs or inspecting legacy code and finding logic driven by historical third-party constraints, document it here immediately.
3. **Do not confuse with `NOTES.md`:** `NOTES.md` tracks recent decisions and general contracts. `INVARIANTS.md` tracks **strict constraints and untouchable legacy quirks**.

---

## 1. Rigid External & Legacy Contracts

| Touchpoint | Invariant Rule | Rationale / Impact |
| :--- | :--- | :--- |
| `[e.g.: /api/v1/webhook]` | `[Retain header X-Legacy-Token]` | `[External partner does not support Bearer tokens]` |
| `[e.g.: Field customer_code]` | `[Retain leading zeroes string]` | `[Legacy ERP crashes if sent integer]` |
| `[e.g.: Payment Payload]` | `[Monetary values in integer cents]` | `[Payment gateway rejects float/decimal]` |

---

## 2. Frozen Dependencies & Environment

- **Locked Versions:**
  - `[e.g.: Library X version 2.4.1]`: Do not update. Version 3.x dropped support for legacy worker protocol.
  - `[e.g.: Python/Node version X]`: Do not bump in Dockerfile without validating native C library compilation.

---

## 3. Justified Workarounds & Non-Obvious Behaviors

Document code segments that look like anti-patterns but exist for valid historical reasons:

### [Module or Function Name]
- **What the code does:** [e.g. A 200ms `sleep()` before confirming database write]
- **Why it seems wrong:** [e.g. Introduces artificial synchronous latency]
- **Why it MUST NOT be removed:** [e.g. Read-replica has async replication lag and the immediate callback webhook queries the replica]

---

## 4. Undocumented Critical Business Rules

- `[Rule 1]`: [e.g.: Corporate accounts cannot be transitioned to 'archived' status via API directly, only through the expiration queue].
- `[Rule 2]`: [e.g.: Username casing must remain unaltered because historical database search is case-sensitive].
