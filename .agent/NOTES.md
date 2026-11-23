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

Canonical 3-tier subagent topology, Tier 2 (`dev-harness`) micro-contracts, worktree isolation, and hermetic sandboxes (specifications: [`docs/subagent-topology.md`](../docs/subagent-topology.md), [`docs/worktree-isolation.md`](../docs/worktree-isolation.md), and [`docs/agent-sandbox.md`](../docs/agent-sandbox.md)):

| Role | Interface / Channel | Responsibilities | Boundary & Invariants |
|---|---|---|---|
| **`Lead / Orchestrator`** | `.agent/TASK.md` / Interactive Prompt | Decomposes initiatives into wave-compatible tasks, manages task lifecycle, routes to model/quota tiers, interacts with human. | Sole manager of `TASK.md` and commit log. Does not run parallel worker tasks directly. |
| **`Worker / Implementer`** | Worktree / Target Workspace | Executes atomic code/doc changes strictly adhering to delegated micro-contract (`files_read`, `files_edit`, `verify`). | Restricted exclusively to `files_edit`. Adheres to DoD in `AGENTS.md`. |
| **`Reviewer / Sentinel`** | Diffs / Test Harness (`verify`) | Read-only inspection of diffs against task DoD, regression tests, and security blast radius. | Read-only; reports structured Pass/Fail diagnostic payload. |

#### Worktree Isolation & Dependency Bootstrap Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Workspace Provisioning** | `git worktree add -b task-<id> <path> HEAD` | Default ephemeral path (`${TMPDIR:-/tmp}/worktrees/task-<id>`) or `.worktrees/task-<id>` (`.worktrees/` in `.gitignore`). |
| **Dependency Bootstrap** | Fast-Link vs. Isolated-Install | Fast-Link (symlink `node_modules/` or `.venv/`) when `files_edit` has no manifest changes (<50ms, zero-copy). Isolated-Install when manifests change. |
| **Environment Injection** | Copy `.env` / `.env.example` to worktree | Ensures test harness execution without leaking uncommitted tokens or mutating root config. |
| **Teardown & GC** | `git worktree remove --force` + `branch -D` + `prune` | Immediate cleanup post-integration; trap declared in runners to prevent dangling worktree locks. |

#### Project Lifecycle Hooks & Fast-Link Bootstrap Contract

| Hook / Phase | Script Target | Invocation & Contract |
|---|---|---|
| **Fast-Link Bootstrap** | `bootstrap-worktree.sh` | Zero-copy symlinking of `node_modules/` and `.venv/`, `.env` isolation copy, and `.agent/scratch/` provisioning. |
| **Post-Provisioning** | `.agent/hooks/post-worktree-create` | Executed post-bootstrap for test DB seeding, port binding, and ephemeral fixtures. Halts on non-zero exit. |
| **Pre-Verification** | `.agent/hooks/pre-verify` | Executed before `verify` command execution to ensure clean test state and fixture validation. |
| **Post-Teardown** | `.agent/hooks/post-worktree-teardown` | Executed prior to worktree removal (`git worktree remove`) for graceful daemon/resource teardown. |

#### Multi-Account Quota Routing & Failover Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Profile Routing Priority** | `select-profile.sh --exclude-current` | Autonomous workers route to secondary accounts with highest quota; active IDE profile reserved for Lead Orchestrator. |
| **Quota Floor Circuit Breaker** | `remaining_fraction <= 0.05` | Immediate disqualification of profiles with <=5% quota; halts execution if all candidate profiles are below floor. |
| **Model Tier Selection** | `default-tier` / `escalation-tier` (mapped via `WORKER_MODEL_DEFAULT_TIER` / `WORKER_MODEL_ESCALATION_TIER`) | Low token footprint default; escalation to `escalation-tier` permitted only for complex architecture or max 1 retry after verification failure. |
| **Cooldown Tracking** | `<profile>/.multigravity/quota-history.jsonl` | 429 rate limit backoff and cooldown persistence to prevent immediate re-dispatch. |
| **Worktree Recovery** | Worktree verify on timeout | Runs `verify` inside worktree on timeout; if code 0 and matches `files_edit`, recovers diff cleanly. |

#### Hermetic Agent Sandbox & Container Isolation Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Tier 1 (Bubblewrap)** | `bwrap --unshare-all --ro-bind /usr ...` | Rootless user namespace, read-only system binaries, ephemeral tmpfs `/tmp`, worktree read-write bind, `--die-with-parent`. |
| **Tier 2 (Rootless Container)** | `podman run --read-only --cap-drop=ALL` | Rootless OCI container, read-only rootfs, `no-new-privileges`, memory (2G) and CPU (2.0) limits, tmpfs `/tmp` with `noexec`. |
| **Network Namespacing** | `--unshare-net` / `--network none` | Hermetic air-gap by default; egress permitted exclusively for explicit external API or dependency fetching tasks. |
| **Fallback & Escalation** | `audit-command-security.sh` | Static pre-execution audit for hazardous commands (`sudo`, `/etc` writes, curl pipes) when namespaces unavailable. |

#### LLM Gateway & Virtual Model Routing Contract

Canonical OpenAI v1 compatible gateway integration, virtual model aliases, network boundaries, and timeout invariants (specification: [`docs/llm-gateway.md`](../docs/llm-gateway.md)):

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **API Protocol** | OpenAI v1 (`/v1/chat/completions`, `/v1/models`, `/v1/hydra/models`) | Standard JSON schema, streaming SSE, tool calling via `hydra-llm-router`; discover operator-configured virtual aliases via `/v1/models` or `/v1/hydra/models` with zero provider-specific SDK lock-in. |
| **Virtual Model Routing** | `fast` vs. `deep` | Operator-configured virtual aliases (`fast` default for low-latency <1.5s intent/extractions; `deep` opt-in for complex reasoning/synthesis up to 1M tokens). Upstream provider drift handled dynamically at `hydra-llm-router`. |
| **Network Isolation** | `hydra_shared_net` (`external: true`) | Co-located sibling containers join `hydra_shared_net` for direct DNS `http://hydra-llm-router:3000/v1` (external hosts use `https://hydra-router.homelab.yegear.dev/v1` without `hydra_shared_net`). Joining `hydra_router_internal` or legacy `hydra_ai_net` is strictly forbidden (protects Redis/DB). |
| **Client Timeout & Budget** | `LLM_TIMEOUT_SECONDS >= 180` | Minimum 180s timeout for deep reasoning calls; minimum `max_tokens >= 60` on test probes to prevent empty completions caused by reasoning token consumption. |
| **Token Tiers** | Tier 1 (5M), Tier 2 (1M), Tier 3 (unlimited) | Tier 1 for production pipelines, Tier 2 for interactive/dev, Tier 3 for smoke/health checks. |

---

## Pitfalls & Gotchas

- **`curl | bash` in `install.sh`:** Do not read confirmation from stdin; use `/dev/tty` or `-y`.
- **Cherry-pick, never merge:** Distinct root filetrees; merge pollutes starters.
- **Starter CI:** The job on `main` runs `git show origin/<branch>:init.sh` — requires `fetch-depth: 0`.
- **Brownfield `install.sh`:** Does not copy `.gitignore` or `.env.example` — existing project already has them. Starter CI must not require them on injection target.
- **Healthcheck Probe Log Suppression:** Do not allow periodic HTTP 200 healthcheck pings to flood access logs or VictoriaLogs; suppress successful `/health` and `/healthz` access logs at the proxy or application layer (see `infra:k-002`).
- **Git History Purge & Identity Neutralization:** Historical purge executed across pre-existing branches on 2026-10-28 using `git-filter-repo` with canonical generic identity `Antigravity Lead <lead@template-hub.internal>` (any re-application requires `git push --force-with-lease --all --tags`); subsequent hub development commits use the active contributor identity configured in Git.
- **Circuit Breaker Threshold:** General development starters (`main`, `greenfield`, `brownfield`) use 3 consecutive failures with identical root cause to allow hypothesis exploration. Sensitive starters (`blackbox`, `infra`, `baremetal`) enforce 2 consecutive failures to prevent IP bans or host/daemon disruption.
- **2-Tier Progressive Rigor (supersedes `APPROVED` / `[PARALLEL: Wx]` / `[BATCH: Bx]` task tags):** Tier 1 (interactive, default) uses a lean `- [ ]` checklist in `.agent/TASK.md` validated by the repository's canonical commands. Tier 2 (autonomous) uses strict `files_read` / `files_edit` / `verify` micro-contracts in `.harness/queue/<id>.{md,yaml}` or `harness:ready` GitHub Issues consumed by `dev-harness`. `.agent/hooks/{post-worktree-create,pre-verify,post-worktree-teardown}` remain the compatibility surface for both. The full wave/batch/spec-anchor workflow lives in `ye-sandbox/template-agent-swarm`.
- **LLM Gateway Reasoning Tokens & Timeouts:** When calling thinking-enabled models via `deep`, always set client HTTP timeouts $\ge 180$ seconds. Test assertions and smoke probes must allocate `max_tokens >= 60`; very low caps (e.g. 5 tokens) cause reasoning tokens to consume the entire budget, returning an empty response body. Consumer containers must never attach to `hydra_router_internal` or legacy `hydra_ai_net` (use `hydra_shared_net` only for co-located sibling containers on the same Docker host).
