# NOTES.md — Active Host Contracts, Decisions, and Gotchas

> Stores active workstation contracts, multi-agent ensemble roles, and critical OS gotchas.
> Hardware inventory lives in [`.agent/BASELINE.md`](BASELINE.md).
> Optimization history and rollback links live in [`.agent/TUNINGS.md`](TUNINGS.md).
> Architectural decisions live in [`docs/adr/decisions.md`](../docs/adr/decisions.md).

---

## How to Use this File (for the Agent)

1. **Read before planning any task:** Active contracts prevent destructive commands and unintended system downtime.
2. **Keep this file lean:** Only record active operational contracts, gotchas, and assumed technical debt.
3. **Decisions & Rationale:** Record in [`docs/adr/decisions.md`](../docs/adr/decisions.md) WHY optimizations were configured or why certain parameters were avoided.
4. **CRITICAL INVARIANT:** NEVER create task-specific headings (e.g., `## [Task XX.Y] Description` or `### [Task XX.Y]`) in `NOTES.md`. Task completion details live in `git log` and `.agent/ARCHIVE.md`. Architectural decisions live in `docs/adr/decisions.md`. In `NOTES.md`, maintain and update ONLY the live tables/lists of active contracts, interfaces, and topology.

---

## Active Contracts

### 1. Active Storage & Privilege Invariants

- **Backup Standard:** Every modified system file is backed up to `.backups/<timestamp>-<slug>/` before write.
- **Privilege Boundary:** No automated execution of `sudo` without displaying the full script and receiving human confirmation.

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

## Gotchas and Quirks

- **zram vs swapfile priority:** When using both zram and a disk swapfile, ensure zram has a higher priority (`pri=100`) than the disk partition (`pri=10`) in `/etc/fstab` or systemd-zram-generator.
- **Sysctl persistence across reboots:** Do not edit `/etc/sysctl.conf` directly on modern systemd distributions; place individual files in `/etc/sysctl.d/99-<name>.conf`.
- **Systemd user vs system units:** Dotfiles and desktop tweaks belong to `systemctl --user`, avoiding unnecessary `sudo` elevation.

---

## Assumed Technical Debt

| Debt | Decision Rationale | Revisit When |
|---|---|---|
| `[e.g. Manual script execution]` | `[Preferring explicit sudo prompts over automated daemon]` | `[When fully trusted Ansible/playbook is needed]` |
