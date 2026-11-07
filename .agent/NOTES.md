# NOTES.md — Hub Decisions, Context, and Contracts

> Stores the WHY. The WHAT lives in `git log` / `.agent/TASK.md`. Before writing:
> does this explain a rationale, or merely describe a diff? If descriptive, the commit is enough.

---

## Usage Guidelines

1. Read before planning. Decisions here take precedence over "obvious defaults", unless explicitly revisited.
2. Record: trade-offs, contracts, gotchas, new skills, deliberate technical debt.
3. Do not record: file lists, changelogs, passing tests.
4. Architectural decisions $\rightarrow$ record in [`docs/adr/decisions.md`](../docs/adr/decisions.md) (Progressive Disclosure). Keep only active runtime contracts here.
5. **CRITICAL INVARIANT:** NEVER create task-specific headings (e.g., `## [Task XX.Y] Description` or `### [Task XX.Y]`) in `NOTES.md`. Task completion details live in `git log` and `.agent/ARCHIVE.md`. Architectural decisions live in `docs/adr/decisions.md`. In `NOTES.md`, maintain and update ONLY the live tables/lists of active contracts, interfaces, and topology.

---

## Decisions (Historical Diary)

Historical decisions are consolidated in [`docs/adr/decisions.md`](../docs/adr/decisions.md) (Progressive Disclosure).
Active contracts and live gotchas stay below.

---

## Active Contracts

### Multi-Agent Collaboration Contracts

Canonical 3-tier subagent topology, delegation micro-contracts, worktree isolation, and hermetic sandboxes (specifications: [`docs/subagent-topology.md`](../docs/subagent-topology.md), [`docs/worktree-isolation.md`](../docs/worktree-isolation.md), and [`docs/agent-sandbox.md`](../docs/agent-sandbox.md)):

| Role | Interface / Channel | Responsibilities | Boundary & Invariants |
|---|---|---|---|
| **`Lead / Orchestrator`** | `.agent/TASK.md` / Interactive Prompt | Decomposes initiatives into wave-compatible tasks, manages task lifecycle, routes to model/quota tiers, interacts with human. | Sole manager of `TASK.md` and commit log. Does not run parallel worker tasks directly. |
| **`Worker / Implementer`** | Worktree / Target Workspace | Executes atomic code/doc changes strictly adhering to delegated micro-contract (`Read:`, `Paths:`, `Verify:`). | Restricted exclusively to `Paths:`. Adheres to DoD in `AGENTS.md`. |
| **`Reviewer / Sentinel`** | Diffs / Test Harness (`Verify:`) | Read-only inspection of diffs against task DoD, regression tests, and security blast radius. | Read-only; reports structured Pass/Fail diagnostic payload. |

#### Worktree Isolation & Dependency Bootstrap Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Workspace Provisioning** | `git worktree add -b task-<id> <path> HEAD` | Default ephemeral path (`${TMPDIR:-/tmp}/worktrees/task-<id>`) or `.worktrees/task-<id>` (`.worktrees/` in `.gitignore`). |
| **Dependency Bootstrap** | Fast-Link vs. Isolated-Install | Fast-Link (symlink `node_modules/` or `.venv/`) when `Paths:` has no manifest changes (<50ms, zero-copy). Isolated-Install when manifests change. |
| **Environment Injection** | Copy `.env` / `.env.example` to worktree | Ensures test harness execution without leaking uncommitted tokens or mutating root config. |
| **Teardown & GC** | `git worktree remove --force` + `branch -D` + `prune` | Immediate cleanup post-integration; trap declared in runners to prevent dangling worktree locks. |

#### Project Lifecycle Hooks & Fast-Link Bootstrap Contract

| Hook / Phase | Script Target | Invocation & Contract |
|---|---|---|
| **Fast-Link Bootstrap** | `bootstrap-worktree.sh` | Zero-copy symlinking of `node_modules/` and `.venv/`, `.env` isolation copy, `.agent/scratch/` provisioning. |
| **Post-Provisioning** | `.agent/hooks/post-worktree-create` | Executed post-bootstrap for test DB seeding, port binding, and ephemeral fixtures. Halts on non-zero exit. |
| **Pre-Verification** | `.agent/hooks/pre-verify` | Executed before `Verify:` command execution to ensure clean test state and fixture validation. |
| **Post-Teardown** | `.agent/hooks/post-worktree-teardown` | Executed prior to worktree removal (`git worktree remove`) for graceful daemon/resource teardown. |

#### Multi-Account Quota Routing & Failover Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Profile Routing Priority** | `select-profile.sh --exclude-current` | Autonomous workers route to secondary accounts with highest quota; active IDE profile reserved for Lead Orchestrator. |
| **Quota Floor Circuit Breaker** | `remaining_fraction <= 0.05` | Immediate disqualification of profiles with <=5% quota; halts execution if all candidate profiles are below floor. |
| **Model Tier Selection** | `gemini-3.8-flash-medium` | Low token footprint default; escalation to `gemini-4-argon-medium` permitted only for complex architecture or max 1 retry after verification failure. |
| **Cooldown Tracking** | `<profile>/.multigravity/quota-history.jsonl` | 429 rate limit backoff and cooldown persistence to prevent immediate re-dispatch. |
| **Worktree Recovery** | Worktree verify on timeout | Runs `Verify:` inside worktree on timeout; if code 0 and matches `Paths:`, recovers diff cleanly. |

#### Hermetic Agent Sandbox & Container Isolation Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Tier 1 (Bubblewrap)** | `bwrap --unshare-all --ro-bind /usr ...` | Rootless user namespace, read-only system binaries, ephemeral tmpfs `/tmp`, worktree read-write bind, `--die-with-parent`. |
| **Tier 2 (Rootless Container)** | `podman run --read-only --cap-drop=ALL` | Rootless OCI container, read-only rootfs, `no-new-privileges`, memory (2G) and CPU (2.0) limits, tmpfs `/tmp` with `noexec`. |
| **Network Namespacing** | `--unshare-net` / `--network none` | Hermetic air-gap by default; egress permitted exclusively for explicit external API or dependency fetching tasks. |
| **Fallback & Escalation** | `audit-command-security.sh` | Static pre-execution audit for hazardous commands (`sudo`, `/etc` writes, curl pipes) when namespaces unavailable. |

---

## Pitfalls & Gotchas

- **`curl | bash` in `install.sh`:** Do not read confirmation from stdin; use `/dev/tty` or `-y`.
- **Cherry-pick, never merge:** Distinct root filetrees; merge pollutes starters.
- **Starter CI:** The job on `main` runs `git show origin/<branch>:init.sh` — requires `fetch-depth: 0`.
- **Brownfield `install.sh`:** Does not copy `.gitignore` or `.env.example` — existing project already has them. Starter CI must not require them on injection target.
- **Healthcheck Probe Log Suppression:** Do not allow periodic HTTP 200 healthcheck pings to flood access logs or VictoriaLogs; suppress successful `/health` and `/healthz` access logs at the proxy or application layer (see `infra:k-002`).
- **Git History Purge & Identity Neutralization:** Complete purge executed across all branches using `git-filter-repo` with canonical generic identity `Antigravity Lead <lead@template-hub.internal>`. All historical commit hashes across branches have been rewritten; upstream publication requires `git push --force-with-lease --all --tags`.
- **Circuit Breaker Threshold:** General development starters (`main`, `greenfield`, `brownfield`) use 3 consecutive failures with identical root cause to allow hypothesis exploration. Sensitive starters (`blackbox`, `infra`, `baremetal`) enforce 2 consecutive failures to prevent IP bans or host/daemon disruption.
- **Pre-Approved Tasks (`APPROVED`), Parallel Waves (`[PARALLEL: Wx]`) & `task-queue` Skill:** Tasks finalized during interactive planning use `Status: APPROVED` in `.agent/TASK.md` (with independent disjoint-file tasks tagged `[PARALLEL: Wx]` and structured with the `Read: / Paths: / Verify:` micro-contract), allowing fresh sessions (`proceed`) or isolated worker subagents and multi-account quota failover (`task-queue` skill via `run-wave.sh` on `proceed queue`, defaulting to `gemini-3.8-flash-medium`) to transition directly to `RUNNING` without a redundant `PLANNING` pause, halting only when ambiguities, unapproved dependencies, or blockers require human intervention.
