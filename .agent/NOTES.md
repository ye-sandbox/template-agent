# NOTES.md — Active Host Contracts, Decisions, and Gotchas

> Stores active workstation contracts, multi-agent ensemble roles, and critical OS gotchas.
> Hardware inventory lives in [`.agent/BASELINE.md`](BASELINE.md).
> Optimization history and rollback links live in [`.agent/TUNINGS.md`](TUNINGS.md).

---

## How to Use this File (for the Agent)

1. **Read before planning any task:** Active contracts prevent destructive commands and unintended system downtime.
2. **Keep this file lean:** Only record active operational contracts, gotchas, and assumed technical debt.
3. **Decisions & Rationale:** Record WHY optimizations were configured or why certain parameters were avoided.

---

## Active Host & Multi-Agent Contracts

### 1. Multi-Agent Topology & Ensemble Contract (Dev Trinity Sentinel)

When operating under Maestri / Antigravity orchestration:
- **Planner:** Manages `.agent/TASK.md` and prioritizes non-destructive optimizations.
- **Operator (Developer):** Inspects OS state, writes symmetrical `apply` and `revert` scripts.
- **Auditor:** Verifies pre-change backups exist in `.backups/`, asserts syntax (`bash -n`), and checks invariants.
- **Host Sentinel:** Live supervisor monitoring commands for blacklisted patterns (`rm -rf /etc`, `dd`, `apt purge`).

### 2. Active Storage & Privilege Invariants

- **Backup Standard:** Every modified system file is backed up to `.backups/<timestamp>-<slug>/` before write.
- **Privilege Boundary:** No automated execution of `sudo` without displaying the full script and receiving human confirmation.

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
