# TASK.md — Current Baremetal Task and Roadmap

> Defines WHAT needs to be done in host and workstation optimization. Detailed history lives in `git log`.
> User requests during conversation take precedence — report discrepancies before acting.

---

## Active Task

### 📌 Task [00.1]: Baseline System Audit & Performance Discovery

- **Description:** Run non-destructive host diagnostics to audit hardware capabilities (CPU, RAM, storage, GPU), capture baseline OS/kernel parameters (swappiness, dirty ratios, I/O schedulers), record active systemd services, and populate `.agent/BASELINE.md` and `.agent/INVARIANTS.md`.
- **Systems Involved:** `baremetal`, `os-audit`, `baseline`
- **Action Type:**
  - [x] Read-only / Documentation
  - [ ] Source code changes
- **Status:** READY FOR PLANNING
  *(Workflow: `READY FOR PLANNING` → `PLANNING` on presenting plan → approval → `RUNNING`)*

### Acceptance Criteria
- [ ] Hardware topology recorded in `.agent/BASELINE.md` (`lscpu`, `free -h`, `lsblk`).
- [ ] Operating system and kernel version documented.
- [ ] Baseline memory metrics and swap/zram configuration recorded.
- [ ] Essential host invariants confirmed in `.agent/INVARIANTS.md`.
- [ ] Initial boot analysis captured (`systemd-analyze`).
- [ ] Smoke test passes: `npm test`.

---

## Completed Tasks Log

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[00.0]` | Initial baremetal template scaffolding | [`0000000`] | `YYYY-MM-DD` |

---

## Backlog (Upcoming, in priority order)

- [ ] **[01.1]** Memory subsystem tuning: optimize `vm.swappiness` and `vfs_cache_pressure` with rollback pair
- [ ] **[01.2]** Storage and I/O scheduler tuning: verify NVMe scheduler and dirty page ratios
- [ ] **[02.1]** Background systemd unit audit: identify and disable redundant startup services

---

## Release / Cycle Wrap-up (Not the next task)

Release/tag only with explicit human request. When triggered, the ID is `[99.1]`. Do not number feature, hygiene, or CI tasks as `99.x`. Do not calculate next task ID from this section.

---

## Future Backlog / Ideas (Unprioritized)

- [ ] Configure zram compressed swap with zstd algorithm
- [ ] CPU governor optimization for developer workstations (performance vs powersave)
- [ ] Periodic TRIM automation for NVMe SSD drives

---

## How to Keep this File Lean

1. Detail only in the active task. When complete $\rightarrow$ log one line and promote the next task.
2. Next ID = last ID in log (or active task). Cycle wrap-up and `[99.1]`: see `AGENTS.md`.
