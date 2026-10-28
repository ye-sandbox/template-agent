# NOTES.md — Hub Decisions, Context, and Contracts

> Stores the WHY. The WHAT lives in `git log` / `.agent/TASK.md`. Before writing:
> does this explain a rationale, or merely describe a diff? If descriptive, the commit is enough.

---

## Usage Guidelines

1. Read before planning. Decisions here take precedence over "obvious defaults", unless explicitly revisited.
2. Record: trade-offs, contracts, gotchas, new skills, deliberate technical debt.
3. Do not record: file lists, changelogs, passing tests.
4. Architectural decisions $\rightarrow$ record in [`docs/adr/decisions.md`](../docs/adr/decisions.md) (Progressive Disclosure). Keep only active runtime contracts here.

---

## Decisions (Historical Diary)

Historical decisions are consolidated in [`docs/adr/decisions.md`](../docs/adr/decisions.md) (Progressive Disclosure).
Active contracts and live gotchas stay below.

---

## Pitfalls & Gotchas

- **`curl | bash` in `install.sh`:** Do not read confirmation from stdin; use `/dev/tty` or `-y`.
- **Cherry-pick, never merge:** Distinct root filetrees; merge pollutes starters.
- **Starter CI:** The job on `main` runs `git show origin/<branch>:init.sh` — requires `fetch-depth: 0`.
- **Brownfield `install.sh`:** Does not copy `.gitignore` or `.env.example` — existing project already has them. Starter CI must not require them on injection target.
- **Healthcheck Probe Log Suppression:** Do not allow periodic HTTP 200 healthcheck pings to flood access logs or VictoriaLogs; suppress successful `/health` and `/healthz` access logs at the proxy or application layer (see `infra:k-002`).
- **Git History Purge & Identity Neutralization:** Complete purge executed across all branches using `git-filter-repo` with canonical generic identity `Antigravity Lead <lead@template-hub.internal>`. All historical commit hashes across branches have been rewritten; upstream publication requires `git push --force-with-lease --all --tags`.
