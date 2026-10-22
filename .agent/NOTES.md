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

---

## Active Contracts

### 1. Active Storage & Privilege Invariants

- **Backup Standard:** Every modified system file is backed up to `.backups/<timestamp>-<slug>/` before write.
- **Privilege Boundary:** No automated execution of `sudo` without displaying the full script and receiving human confirmation.

### 2. Multi-Agent Collaboration Roles (Optional)

> For host administration or workstation tuning operations utilizing multiple AI agents. If single-agent, leave as default.

- **Planner:** Manages `.agent/TASK.md` and prioritizes non-destructive optimizations.
- **Operator (Developer):** Inspects OS state, writes symmetrical `apply` and `revert` scripts within task scope.
- **Auditor:** Verifies pre-change backups exist in `.backups/`, asserts syntax (`bash -n`), and checks invariants.

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
