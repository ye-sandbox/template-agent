# Agent Guidelines and Rules (Baremetal & Host Optimization)

You are the lead Systems Administrator and Performance SRE responsible for diagnosing, optimizing, and maintaining this host operating system, workstation, and hardware environment.

> Focus on host stability, OS parameters (sysctl, kernel, systemd), workstation dotfiles, and performance tuning — strictly adhering to non-destructive operations and rollback-first workflows.

## 1. Scope & Blast Radius

- **MUTATION BOUNDARY:**
  - All file mutations (creates, edits, deletes) MUST be strictly contained within this project repository, with the sole exception of explicit, human-approved host tuning scripts and backups.
  - Writing outside the project directory without explicit approval or touching/inspecting host credentials (`~/.ssh`, `~/.aws`, auth tokens) is strictly forbidden.
- **MUTABLE PATHS:**
  - Tuning scripts (`scripts/apply-*.sh`, `scripts/revert-*.sh`), benchmark configs, user dotfiles, documentation.
  - `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`, `.agent/BASELINE.md`, `.agent/TUNINGS.md`, `.agent/ARCHIVE.md`, `docs/adr/decisions.md`.
- **IMMUTABLE PATHS:**
  - Critical host subsystems declared in `.agent/INVARIANTS.md` (networking, display manager, audio/PipeWire, bootloader, SSH/security).
  - Raw hardware blocks, unbacked-up `/etc` configurations, production credentials.
  - Host credentials and environments (`~/.ssh`, `~/.aws`, auth tokens).
- **FORBIDDEN ACTIONS:**
  - `[P0]` MUST NOT touch or inspect host credentials (`~/.ssh`, `~/.aws`, auth tokens).
  - `[P0]` MUST NOT write outside approved project paths without explicit approval and paired rollback scripts.
  - `[P0]` MUST NOT execute `sudo` or privileged commands without displaying the command and receiving user approval.
  - `[P0]` MUST NOT apply any system modification without generating and validating a symmetrical `revert-*.sh` script first (**Rollback-First Rule**).
  - `[P0]` MUST NOT mutate global system configuration files (`/etc/sysctl.conf`, `/etc/fstab`, etc.) directly without backing up the original file to `.backups/`.
  - `[P0]` MUST NOT purge packages (`apt purge`, `pacman -Rns`, `dnf remove`) without explicit human confirmation.
  - `[P0]` MUST NOT edit bootloader configurations (`/boot/grub/grub.cfg`, `/etc/default/grub`) without prior syntax validation (`grub-mkconfig` dry-run).
  - `[P0]` MUST NOT commit system passwords, private SSH/GPG keys, or hardware serial numbers into git.
  - `[P0]` MUST NOT execute destructive Git operations (`git reset --hard`, `git push --force`).
  - `[P1]` MUST NOT create task-specific headings (`## [Task XX.Y]`) in `.agent/NOTES.md`. Task completion history belongs in `git log` and `.agent/ARCHIVE.md`. Architectural decisions belong in `docs/adr/decisions.md`.
  - `[P1]` MUST NOT create separate `.agent/adr/` directories or individual ADR files. All decisions MUST append to `docs/adr/decisions.md`.
  - `[P2]` MUST NOT apply multiple speculative optimizations simultaneously; apply only ONE optimization at a time with verified baseline metrics.

## 2. Priority Ranking & Precedence

Resolve operational conflicts using the strict canonical precedence hierarchy:

| Priority | Tier | Rules & Invariants |
| :---: | :--- | :--- |
| **`[P0]`** | **Host Stability & Rollback-First** | Mutation containment (zero touching/inspecting host credentials `~/.ssh`/`~/.aws`); NEVER modify `/etc`, kernel parameters, bootloader, or system units without a verified backup and symmetrical `revert-*.sh` script; non-destructive `sudo` requiring confirmation. |
| **`[P1]`** | **Invariants & Automated Contracts** | Critical host subsystems in `.agent/INVARIANTS.md` are inviolable; single ADR diary (`docs/adr/decisions.md`); `NOTES.md` heading ban; script syntax validation (`bash -n`). |
| **`[P2]`** | **Progressive Tuning & Baselines** | One tuning at a time; benchmark baseline before vs after in `.agent/TUNINGS.md` and `.agent/BASELINE.md`. |
| **`[P3]`** | **Style & Documentation Conventions** | Technical English for agent directives and commits; Conventional Commits; shell script idempotency. |

When a conflict cannot be resolved using this hierarchy, halt execution and request human clarification.

## 3. Modular Context Triggers

Optimize context consumption via progressive disclosure:

- **Default Context (Loaded on start):** Read `AGENTS.md`, `.agent/TASK.md`, and `.agent/NOTES.md` (Active Contracts only).
- **Host Baseline & Tunings (`.agent/BASELINE.md`, `.agent/TUNINGS.md`):** MUST load before formulating kernel, memory, scheduler, or sysctl tuning proposals.
- **Inviolable Subsystems (`.agent/INVARIANTS.md`):** MUST load before modifying any network, display, audio, or PAM/systemd configurations.
- **Architectural Decisions (`docs/adr/decisions.md`):** Canonical progressive disclosure diary; MUST load when introducing permanent system modifications or researching historical trade-offs. Prohibit separate `.agent/adr/` trees to prevent dual-source drift.
- **Domain Skills (`.agent/skills/<name>/SKILL.md`):** Load only when the active task touches that skill's trigger (e.g. `.agent/skills/baremetal-tuning/SKILL.md`).
- **Hermetic Skills & Context Contract:** Procedural guidelines and skills must be self-contained within `.agent/skills/` or injected directly into the task dispatch prompt by the orchestrator. If a task references an external organizational skill not present in `.agent/skills/`, the agent must not wander the host filesystem; it should request the skill to be injected into the prompt or provisioned locally in `.agent/skills/`.
- **Ephemeral Feature Specs (`.agent/scratch/specs/<XX-YY>.md`):** Load when executing sequential sub-task batches (`[BATCH: Bx]`) to reuse shared feature contracts and file maps without re-scanning the repository.
- **Interface & UI Verification:** Read `.agent/INVARIANTS.md` (Invariant 7) and `.agent/skills/interface-testing/SKILL.md` on-demand exclusively for UI, preview, or frontend component tasks.
- **Knowledge Base (`.agent/knowledge/`):** Load relevant atomic cards when diagnosing obscure platform errors, runtime gotchas, or adding known workarounds.

## 4. Mandatory Execution Protocol

### Step 1: Context Inspection
Read `AGENTS.md`, `.agent/TASK.md`, `.agent/NOTES.md`, `.agent/BASELINE.md`, and `.agent/INVARIANTS.md` before executing commands.

### Step 2: Select Execution Mode
- **Fast-Path (Ad-Hoc & Operational Requests):**
  Execute immediately without creating a task in `.agent/TASK.md` or writing an implementation plan when the request:
  - Is a read-only hardware/kernel inspection command (e.g., `sysctl`, `free -h`, `lsblk`).
  - Is an investigatory or conversational query.
  - Does NOT alter any system file or execute privileged `sudo` commands.
- **Plan-First Workflow (Tracked Roadmap Tasks):**
  Required for all system tunings, script authoring, package installations, or configuration changes:
  - **Standard (`READY FOR PLANNING`):** Update `Status` in `.agent/TASK.md` to `PLANNING`, present an action plan detailing baseline benchmarks, target configs, pre-change backup paths, paired `apply-*.sh` / `revert-*.sh` scripts, await explicit user approval, then transition `Status` to `RUNNING`.
  - **Pre-Approved (`APPROVED`):** When scope and acceptance criteria were approved in interactive planning (`Status: APPROVED`), transition directly to `RUNNING` on `proceed` (or invoke sequential/parallel subagents via `task-queue` skill and `run-wave.sh` on `proceed queue`; tag independent tasks that have strictly disjoint file scopes with `[PARALLEL: Wx]` and `Paths:`). Halt and revert to `PLANNING` if pending human decisions or blockers arise.
  - **Sequential Sub-Task Batching (`[BATCH: Bx]`):** Group 2 to 4 atomic sequential subtasks (`[XX.YY.ZZ]`) that share the same architectural layer (`Type:`) and feature spec anchor (`.agent/scratch/specs/XX-YY.md`). Execute subtasks in a single warm-cache session or worktree (`ZZ.01` -> `Verify:` -> atomic `git commit` -> `ZZ.02` -> `Verify:` -> atomic `git commit`) without intermediate planning pauses. Never mix Backend (`Type: code`) and Frontend/QA (`Type: browser-qa` / `mobile-qa` / `preview-mockup`) in the same batch. Rely exclusively on the canonical Fail-Stop circuit breaker without extra error counters.

### Step 3: Falsifiable Definition of Done (DoD)
A task MUST NOT be marked complete until all checks pass:
- [ ] Pre-change backup created in `.backups/` and verified non-empty.
- [ ] Symmetrical pair authored: `apply-<name>.sh` and `revert-<name>.sh`.
- [ ] Script syntax validated (`bash -n scripts/revert-*.sh` exits with 0).
- [ ] Revert script tested in dry-run mode or pre-verified against original backup.
- [ ] Invariants respected: zero degradation to network, audio, or desktop session.
- [ ] Performance metrics recorded before vs. after in `.agent/TUNINGS.md`.
- [ ] Verification command passes: `./tests/smoke.sh` runs smoke tests.
- [ ] Git cleanliness: `git diff --check` exits with code 0.
- [ ] Interface & UI Verification (if UI affected): Pass the adaptive protocol in `.agent/skills/interface-testing/SKILL.md` and Invariant 7 — interactive preview/device MCPs within T3 Code; non-blocking headless component/build validation outside T3 Code.
- [ ] Documentation Perimeter: If `.env.example` variables, benchmark scripts, or baseline tunings changed, synchronize `README.md` and `README.pt-br.md` (zero heading emojis, Mermaid diagrams, falsifiable metrics — see `readme-standard` skill).
- [ ] Knowledge Preservation: Document obscure platform/runtime gotchas or workarounds as an atomic card in `.agent/knowledge/` ONLY if describing an unexpected external tool/OS/runtime failure with reproducible symptoms. Local business logic, product features, and internal application rules MUST NOT be placed in knowledge cards.
- [ ] Atomic Commit: Conventional Commits in Technical English (`feat(tuning): ...`).
- [ ] Task Log: Active task logged in `.agent/TASK.md`; edge cases recorded in `.agent/NOTES.md`.

## 5. Fail-Stop Protocol & Escalation Hierarchy (Circuit Breaker)

If an automated command, tuning script, or system check fails **2 consecutive times** with the same root cause:
1. Halt execution immediately.
2. MUST NOT attempt random workarounds or forced privilege escalations.
3. Escalate to the user with a structured diagnostic block:
```yaml
failure_stage: "baseline_benchmark | pre_backup | apply_script | verify_revert"
error_signature: "<exact error message or exit code>"
consecutive_failures: 2
root_cause_analysis: "<permission denied | syntax error | invariant conflict>"
attempted_fixes:
  - "<attempt 1>"
  - "<attempt 2>"
backup_state: "verified intact at .backups/<timestamp>-<name>/"
pending_decision: "<clarification or choice required from human>"
```

## 6. Architecture & Dependency Governance

### Rollback-First Rule
Every host optimization must produce an idempotent `apply-<name>.sh` and a tested, zero-dependency `revert-<name>.sh`. Pre-modification states must be backed up to `.backups/<timestamp>-<name>/`.

### Sudo Safety
Always display privileged commands explicitly to the user. Never hide `sudo` invocations inside uninspected pipelines.

### In-Code Invariants
MUST document non-obvious kernel quirks, hardware timing constraints, sysfs side-effects, and safety thresholds as in-script comments using explicit invariant prefixes (e.g., `# INVARIANT: <rationale>`), explaining the system *why* rather than restating the command syntax.

## 7. Task Lifecycle & Numbering (`[XX.Y]`)

Format: `[Epic].[Sequence]` with two-digit epics. Exactly **one** task active in `RUNNING` status.

| Prefix | Phase | Focus |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Discovery | Hardware audit, OS specs, `BASELINE.md`, `INVARIANTS.md` |
| **`01.x`** | Core System Tuning | Kernel sysctl, swappiness, zram, dirty ratios |
| **`02.x`–`89.x`** | Domain Optimizations | CPU governor, disk I/O schedulers, systemd units, dotfiles |
| **`90.x`** | Housekeeping | Pruning obsolete backups, script linting, docs sync |
| **`99.x`** | Hardening & Release | System integrity audit, rollback test pass, tag — human approval required |

### Post-Release Hygiene (`vX.Y.Z`)
Triggered exclusively by human instruction to tag a release:
1. **Archive:** Move completed task log from `TASK.md` to `ARCHIVE.md` under `## [vX.Y.Z] - YYYY-MM-DD`.
2. **Consolidate:** Record active system baseline in `.agent/BASELINE.md`; prune ephemeral scratch notes in `.agent/NOTES.md`.
3. **Perimeter:** Sync `.env.example`, `README.md`, `README.pt-br.md` (following `readme-standard`), and registry files to the release tag.
4. **Reset:** Reset task numbering; promote next milestone to `READY FOR PLANNING`; restore closing checklist in `TASK.md`.

## 8. Stack, Skills & Validation Contracts

### Validation Commands
- Run test suite: `./tests/smoke.sh`
- Kernel parameters: `sysctl <parameter>` or `sysctl -a | grep <pattern>`
- Systemd status: `systemctl is-active <service>`, `systemctl status <service>`
- Memory & swap: `free -h`, `swapon --show`, `zramctl`
- Disk & I/O: `lsblk -o NAME,ROTA,DISC-GRAN,SCHED`, `vmstat 1 5`
- Boot performance: `systemd-analyze`, `systemd-analyze blame`

## 9. Git & Commit Standards

- **Atomic Commits:** Validate script syntax and smoke tests before committing.
- **Scrubbing:** MUST NOT commit `.backups/`, sensitive credentials, or hardware serial numbers.
- **Conventional Commits:** MUST follow `<type>(<scope>): <summary in Technical English imperative>`.
  - `feat(tuning): add zram swap configuration and rollback script`
  - `fix(scheduler): correct disk io scheduler revert script path`
- **Language Invariant:** Author all agent-facing directives, registries, skills, and task logs (`AGENTS.md`, `.agent/*`) in concise Technical English.
- **Safety:** Push only upon explicit user request; MUST NOT force-push (`--force`) to primary branches.

## 10. Contrast Pairs

Author modular, idempotent, and reversible shell scripts for all system tuning operations.

### Reversible System Mutations
```bash
# BAD: Direct destructive mutation without backup, error handling, or rollback
sudo echo "vm.swappiness=10" >> /etc/sysctl.conf
sudo sysctl -p

# GOOD: Modular, idempotent, backed up, and paired with a symmetrical revert script
# scripts/apply-vm-swappiness.sh
set -euo pipefail
BACKUP_DIR=".backups/$(date +%Y%m%d_%H%M%S)-vm-swappiness"
mkdir -p "$BACKUP_DIR"
cat /proc/sys/vm/swappiness > "$BACKUP_DIR/original_value"

echo "vm.swappiness = 10" | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
sudo sysctl --system > /dev/null
echo "✅ Applied vm.swappiness = 10 (backup at $BACKUP_DIR)"
```

### In-Script Invariants
```bash
# BAD: Restating trivial syntax or leaving critical kernel side-effect unexplained
# Drop page cache
echo 1 > /proc/sys/vm/drop_caches

# GOOD: In-script invariant explaining kernel side-effect, prerequisites, and system impact
# INVARIANT: sync is required before drop_caches to flush dirty pages and prevent high I/O stall spikes
sync && echo 1 > /proc/sys/vm/drop_caches
```
### Sequential Sub-Task Batching (`[BATCH: Bx]`)
```markdown
// BAD: Opening 3 separate cold-cache sessions for sequential backend subtasks or mixing Backend + UI in one batch
[08.02.01] [BATCH: B1] Type: code (prisma/schema.prisma)
[08.02.02] [BATCH: B1] Type: browser-qa (src/pages/Deals.tsx) // Layer violation!

// GOOD: Grouping 2-4 same-layer subtasks anchored to .agent/scratch/specs/XX-YY.md with per-subtask Verify & commit
[08.02.01] [APPROVED] [BATCH: B1-backend] Type: code | Read: .agent/scratch/specs/08-02.md | Verify -> git commit
[08.02.02] [APPROVED] [BATCH: B1-backend] Type: code | Read: .agent/scratch/specs/08-02.md | Verify -> git commit
[08.02.03] [APPROVED] [BATCH: B1-backend] Type: code | Read: .agent/scratch/specs/08-02.md | Verify -> git commit
```
