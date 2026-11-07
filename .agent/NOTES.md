# NOTES.md — Active Contracts and Target Invariants

> Stores active integration contracts, session invariants, target quirks, and multi-agent topology.
> Historical architectural decisions live in [`docs/adr/decisions.md`](../docs/adr/decisions.md).
> Endpoint payload specifications live in [`.agent/ENDPOINTS.md`](ENDPOINTS.md).

---

## How to Use this File

1. **Read before planning.** Active session policies and target quirks prevent anti-bot lockouts.
2. **Keep this file lean:** Only store active session states, integration contracts, and critical gotchas.
3. **Architectural decisions:** Record in [`docs/adr/decisions.md`](../docs/adr/decisions.md).
4. **CRITICAL INVARIANT:** NEVER create task-specific headings (e.g., `## [Task XX.Y] Description` or `### [Task XX.Y]`) in `NOTES.md`. Task completion details live in `git log` and `.agent/ARCHIVE.md`. Architectural decisions live in `docs/adr/decisions.md`. In `NOTES.md`, maintain and update ONLY the live tables/lists of active contracts, interfaces, and topology.

---

## Active Contracts

### 1. Active Session & Integration Contracts

- **HTTP Client Baseline:** [e.g. httpx with connection pooling and HTTP/2 support]
- **HTML/DOM Parser:** [e.g. selectolax / BeautifulSoup for mixed encoding HTML]
- **Session Lifecycle:** [e.g. automatic refresh via interceptor on 302 login redirect]

### 2. Multi-Agent Collaboration Contracts (Optional)

> Canonical 3-tier subagent topology, delegation micro-contracts, worktree isolation, and hermetic sandboxes. If operating single-agent, leave as default.

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

#### LLM Gateway & Virtual Model Routing Contract

Canonical OpenAI v1 compatible gateway integration, virtual model aliases, network boundaries, and timeout invariants (specification: [`docs/llm-gateway.md`](../docs/llm-gateway.md)):

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **API Protocol** | OpenAI v1 (`/v1/chat/completions`, `/v1/models`) | Standard JSON schema, streaming SSE, tool calling; zero provider-specific SDK lock-in. |
| **Virtual Model Routing** | `free-fast` vs. `free-deep` | `free-fast` for low-latency (<1.5s) intent/extractions; `free-deep` for complex reasoning/synthesis (up to 1M tokens). Upstream provider drift handled dynamically at gateway. |
| **Network Isolation** | `hydra_shared_net` (`external: true`) | Consumer containers join `hydra_shared_net` for direct DNS `http://hydra-ai-gateway:3000/v1`. Joining `hydra_ai_net` is strictly forbidden (protects Redis/DB). |
| **Client Timeout & Budget** | `LLM_TIMEOUT_SECONDS >= 180` | Minimum 180s timeout for deep reasoning calls; minimum `max_tokens >= 60` on test probes to prevent empty completions caused by reasoning token consumption. |
| **Token Tiers** | Tier 1 (5M), Tier 2 (1M), Tier 3 (unlimited) | Tier 1 for production pipelines, Tier 2 for interactive/dev, Tier 3 for smoke/health checks. |

---

## Target System Invariants & Discovered Quirks

- [e.g.: The portal drops connections that do not send a Chrome-like `User-Agent`.]
- [e.g.: Numerical IDs return 500 if sent with leading zeros.]
- [e.g.: System enforces a mandatory 250ms minimum delay between sequential requests.]
- **LLM Gateway Reasoning Tokens & Timeouts:** When calling thinking-enabled models via `free-deep`, always set client HTTP timeouts $\ge 180$ seconds. Test assertions and smoke probes must allocate `max_tokens >= 60`; very low caps (e.g. 5 tokens) cause reasoning tokens to consume the entire budget, returning an empty response body. Consumer containers must never attach to `hydra_ai_net` (use `hydra_shared_net`).
