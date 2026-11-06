---
author_type: agent-assisted
author: Architecture Team
reviewed_by: Human Lead
date: 2026-11-06
status: accepted
type: architectural-specification
---

# Hermetic Ephemeral Container & Bubblewrap Sandbox Specification

Canonical specification and operational recipes for rootless sandboxing, Bubblewrap (`bwrap`) isolation profiles, network namespacing, read-only root mounts, and tmpfs workspace isolation for autonomous worker agents within the Agent-Driven Development (ADD) Template Hub.

---

## 1. Overview & Security Philosophy

Autonomous coding subagents execute shell commands, compile source code, download dependencies, and run test suites. Without strict isolation boundaries, an untrusted or hallucinating agent poses severe operational risks:

1. **Host Mutation & State Drift:** Uncontrolled modification of `/etc`, system binaries, global caches, or home directory dotfiles (`~/.bashrc`, `~/.ssh`, `~/.aws`).
2. **Credential Exfiltration & Network Leaks:** Unauthorized outbound HTTP/DNS requests leaking API keys, private repository tokens, or environment secrets.
3. **Unbounded Resource Exhaustion:** Fork bombs, unconstrained memory consumption, or lingering background daemon processes starving host resources.
4. **Workspace Escape:** Reading or overwriting files outside the delegated task scope (`Paths:` whitelist).

To counter these risks while preserving high developer velocity, this specification defines a **Dual-Tier Hermetic Sandbox Architecture**:
- **Tier 1: Bubblewrap (`bwrap`) Profile:** Unprivileged user namespace virtualization for native Linux hosts and lightweight CI runners (zero daemon, sub-millisecond startup, no root privileges).
- **Tier 2: Rootless Ephemeral Container Profile (Podman / Docker):** OCI container isolation with immutable rootfs and seccomp filtering for macOS/Windows developer workstations (via VM backends) and container-native CI environments.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Lead / Orchestrator Task                        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Micro-Contract (Read:, Paths:, Verify:)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    Isolation Profile Auto-Detection                     │
│  1. Check for `bwrap` (Native Linux Namespaces)                        │
│  2. Fallback to `podman` or `docker` (Rootless Ephemeral Container)    │
│  3. Fallback to Restricted Subshell (Alert & Guardrail Enforcement)    │
└───────────────────┬────────────────────────────────┬───────────────────┘
                    │                                │
         ┌──────────┴──────────┐          ┌──────────┴──────────┐
         ▼                     ▼          ▼                     ▼
┌───────────────────────────────┐        ┌───────────────────────────────┐
│     Tier 1: Bubblewrap        │        │   Tier 2: Rootless Container  │
│  • User, PID, IPC, Net NS     │        │  • Podman / Docker Rootless   │
│  • Read-Only /usr, /lib, /etc │        │  • Read-Only rootfs           │
│  • Ephemeral /tmp tmpfs       │        │  • Tmpfs /tmp with noexec     │
│  • Read-Write Worktree Mount  │        │  • Memory & CPU limits        │
│  • Die-with-parent lifecycle  │        │  • Network: none (isolated)   │
└───────────────────────────────┘        └───────────────────────────────┘
```

---

## 2. Tier 1: Bubblewrap (`bwrap`) Isolation Profile

Bubblewrap uses unprivileged user namespaces (`CLONE_NEWUSER`) to create unprivileged sandboxes on Linux. It does not require a running background daemon or `sudo` permissions.

### Core Security Invariants

1. **Rootless & Unprivileged:** Must run as the current unprivileged UID/GID without `sudo` or setuid escalation.
2. **Read-Only System Binds:** The entire host filesystem (`/usr`, `/lib`, `/lib64`, `/bin`, `/sbin`, `/etc`) is mounted read-only (`--ro-bind`). Agents cannot mutate operating system binaries or configurations.
3. **Masked Sensitive Host Directories:** Sensitive user paths (`~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.docker`, `/root`) are strictly masked by empty tmpfs mounts or omitted entirely.
4. **Isolated Ephemeral Tmpfs:** Temporary paths (`/tmp`, `/run`, `/var/tmp`) are mounted as ephemeral `tmpfs` mounts that vanish completely upon process termination.
5. **Fresh Proc & Dev Namespaces:**
   - `--proc /proc`: Mounts a fresh process table isolating worker PIDs from the host.
   - `--dev /dev`: Provides only essential devices (`null`, `zero`, `full`, `random`, `urandom`, `tty`), blocking raw storage disk nodes.
6. **Parent Lifecycle Binding (`--die-with-parent`):** Automatically terminates all subagent child processes if the parent orchestrator exits or is cancelled.
7. **Process Group & Session Isolation (`--new-session`):** Detaches the child from the controlling terminal, preventing ioctl terminal injection attacks.

### Canonical Bubblewrap Execution Recipe

```bash
#!/usr/bin/env bash
# run-in-bwrap.sh — Canonical Bubblewrap Sandbox Wrapper
set -euo pipefail

WORKTREE_PATH="${1:-$(pwd)}"
shift || true
COMMAND_TO_RUN="${*:-bash}"

if ! command -v bwrap >/dev/null 2>&1; then
  echo "Error: bwrap (bubblewrap) is not installed." >&2
  exit 127
fi

# Resolve absolute path of the worktree
WORKTREE_ABS="$(cd "${WORKTREE_PATH}" && pwd -P)"

# Build bubblewrap invocation
bwrap \
  --unshare-user \
  --unshare-ipc \
  --unshare-pid \
  --unshare-uts \
  --unshare-net \
  --die-with-parent \
  --new-session \
  --ro-bind /usr /usr \
  --ro-bind-try /lib /lib \
  --ro-bind-try /lib64 /lib64 \
  --ro-bind-try /bin /bin \
  --ro-bind-try /sbin /sbin \
  --ro-bind-try /etc /etc \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /var \
  --tmpfs "${HOME}" \
  --bind "${WORKTREE_ABS}" "${WORKTREE_ABS}" \
  --chdir "${WORKTREE_ABS}" \
  --setenv PATH "/usr/local/bin:/usr/bin:/bin" \
  --setenv HOME "${HOME}" \
  --setenv TMPDIR "/tmp" \
  -- "$COMMAND_TO_RUN"
```

---

## 3. Tier 2: Rootless Ephemeral Container Profile (Podman / Docker)

For environments where Bubblewrap is unavailable or cross-platform OCI image reproducibility is required (e.g. macOS via Podman machine, Docker Desktop, or Kubernetes CI jobs), execution is containerized.

### Container Security Invariants

| Security Dimension | Enforcement Flag | Rational & Threat Mitigated |
| :--- | :--- | :--- |
| **User Identity** | `--user 1000:1000` | Prevents root execution inside container; matches host file ownership. |
| **Root Filesystem** | `--read-only` | Prevents file modification outside designated writable mounts. |
| **Privilege Escalation** | `--security-opt=no-new-privileges` | Blocks setuid binaries (`sudo`, `su`) from gaining root privileges. |
| **Linux Capabilities** | `--cap-drop=ALL` | Drops all kernel capabilities (raw sockets, sys_admin, ptrace). |
| **Memory Limit** | `--memory=2g --memory-swap=2g` | Prevents out-of-memory denial of service on host. |
| **CPU Limit** | `--cpus=2.0` | Prevents runaway worker threads from starving orchestrator CPU. |
| **PID Limit** | `--pids-limit=256` | Blocks fork bombs and excessive background thread creation. |
| **Temporary Storage** | `--tmpfs /tmp:rw,noexec,nosuid,size=512m` | Ephemeral memory-backed tmpfs; disables binary execution in `/tmp`. |
| **Ephemeral Teardown** | `--rm` | Automatically cleans up container state and volumes on exit. |

### Canonical Rootless Container Execution Recipe

```bash
#!/usr/bin/env bash
# run-in-container.sh — Canonical Rootless Container Sandbox Wrapper
set -euo pipefail

CONTAINER_ENGINE=""
if command -v podman >/dev/null 2>&1; then
  CONTAINER_ENGINE="podman"
elif command -v docker >/dev/null 2>&1; then
  CONTAINER_ENGINE="docker"
else
  echo "Error: Neither podman nor docker is installed." >&2
  exit 127
fi

WORKTREE_PATH="${1:-$(pwd)}"
shift || true
COMMAND_TO_RUN="${*:-sh}"

WORKTREE_ABS="$(cd "${WORKTREE_PATH}" && pwd -P)"
IMAGE_NAME="${AGENT_SANDBOX_IMAGE:-node:lts-alpine}"

"$CONTAINER_ENGINE" run --rm -i \
  --user "$(id -u):$(id -g)" \
  --read-only \
  --security-opt=no-new-privileges \
  --cap-drop=ALL \
  --network none \
  --memory=2g \
  --memory-swap=2g \
  --cpus=2.0 \
  --pids-limit=256 \
  --tmpfs /tmp:rw,noexec,nosuid,size=512m \
  -v "${WORKTREE_ABS}:/workspace:rw" \
  -w /workspace \
  -e HOME=/tmp \
  -e TMPDIR=/tmp \
  "$IMAGE_NAME" \
  sh -c "$COMMAND_TO_RUN"
```

---

## 4. Network Namespacing & Outbound Filtering

Network isolation is the most critical defense against data exfiltration and reverse shell attacks during autonomous task execution.

### Isolation Policies

1. **Default Mode: Hermetic Air-Gap (`--unshare-net` / `--network none`):**
   - Autonomous code mutation, linting, unit testing, and diff inspection MUST run with zero network access.
   - Loopback interface (`127.0.0.1`) is available internally for multi-process communication or mock servers within the sandbox, but egress to external subnets is blocked.
2. **Conditional Egress Mode (Dependency Bootstrap & Web Scrapers):**
   - When a micro-contract explicitly requires outbound connectivity (e.g. `Isolated-Install` of packages or blackbox scraping tasks):
     - In Bubblewrap: Use `--share-net` with restricted DNS and proxy configuration via environment (`HTTP_PROXY`, `HTTPS_PROXY`).
     - In Rootless Containers: Use user-mode networking (`--network slirp4netns` or bridge with egress firewall rules).
   - Secret scrubbing: All private tokens (`GITHUB_TOKEN`, `API_KEY`) MUST NOT be injected into the sandbox environment when network access is enabled.

---

## 5. Filesystem Layout & Mount Hierarchy

The sandbox enforces a clear separation between immutable system dependencies, ephemeral scratch space, and the mutable task worktree:

```
/ (VFS Root)
├── usr/                  [RO Bind: Host /usr]
├── bin/                  [RO Bind: Host /bin]
├── lib/                  [RO Bind: Host /lib]
├── etc/                  [RO Bind: Host /etc]
├── dev/                  [Minimal Devfs: null, zero, urandom]
├── proc/                 [Isolated Fresh Procfs: PID namespace]
├── tmp/                  [Ephemeral Tmpfs: 512MB RAM disk]
└── workspace/            [RW Bind: Target Git Worktree Path]
    ├── src/              [Accessible according to micro-contract Paths:]
    ├── docs/             [...]
    └── .env              [Injected from .env.example / scrubbed test credentials]
```

### Invariant Checks on Mount Paths

1. **Worktree Bound Exclusivity:** Only the designated worktree path (`${WORKTREE_PATH}`) is mounted read-write. The root git repository directory is NEVER mounted read-write to a worker subagent.
2. **Tmpfs Isolation:** `/tmp` is strictly ephemeral; any files created in `/tmp` are discarded upon exit and cannot contaminate the host filesystem or other tasks.
3. **No Sudo Access:** The sandboxed process has UID matching the host user or 1000, with no entry in `/etc/sudoers` or capability `CAP_SETUID`.

---

## 6. Integration with Micro-Contract & Worktree Lifecycle

The sandbox works seamlessly with the 6-phase Worktree Lifecycle defined in [`docs/worktree-isolation.md`](worktree-isolation.md) and the micro-contract verification runner (`verify-microcontract.sh`):

```bash
# 1. Provision worktree
git worktree add -b "task-04-2" "/tmp/worktrees/task-04-2" HEAD

# 2. Bootstrap dependencies via Fast-Link or Isolated-Install
ln -s "$(pwd)/node_modules" "/tmp/worktrees/task-04-2/node_modules"

# 3. Execute Worker commands inside Hermetic Sandbox
run-in-bwrap.sh "/tmp/worktrees/task-04-2" "npm test"

# 4. Reviewer validates diffs and blast boundaries
verify-microcontract.sh verify-worktree "/tmp/worktrees/task-04-2" task-contract.md --run-verify

# 5. Teardown
git worktree remove --force "/tmp/worktrees/task-04-2"
```

---

## 7. Automated Runtime Detection & Fallback Strategy

The orchestrator determines the sandboxing mechanism using the following deterministic cascade:

```bash
select_sandbox_runner() {
  if command -v bwrap >/dev/null 2>&1; then
    echo "bwrap"
  elif command -v podman >/dev/null 2>&1; then
    echo "podman"
  elif command -v docker >/dev/null 2>&1; then
    echo "docker"
  else
    echo "restricted-subshell"
  fi
}
```

When operating in `restricted-subshell` mode (environments where neither namespaces nor containers can be provisioned):
- The orchestrator falls back to running the pre-execution security scanner (`audit-command-security.sh`) to statically audit commands for dangerous tokens (`sudo`, `rm -rf /`, curl-piping, `/etc` modifications) prior to execution.
- Any attempt to execute dangerous system commands triggers the **Fail-Stop Escalation Protocol** defined in `AGENTS.md`.
