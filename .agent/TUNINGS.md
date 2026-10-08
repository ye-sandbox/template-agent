# TUNINGS.md — Canonical Registry of System Optimizations

> Tracks every optimization, configuration change, kernel tweak, and service modification applied to this host.
> 
> ⚖️ **Rollback-First Contract:** Every active tuning MUST point to a verified pre-change backup and a working `scripts/revert-*.sh` script.

---

## 📋 Active & Historical Tunings Registry

| ID | Date | Subsystem | Title & Target | Backup Path | Apply Script | Revert Script | Status | Metric Diff |
|---|---|---|---|---|---|---|---|---|
| `[T-00]` | `YYYY-MM-DD` | `bootstrap` | Baseline System Audit & Discovery | N/A (read-only) | N/A | N/A | `BASELINE` | System inventory recorded in `BASELINE.md` |

---

## Status Legend

- `BASELINE`: Initial state recorded during discovery.
- `PENDING`: Plan and scripts authored; awaiting user review/execution.
- `APPLIED`: Successfully executed, verified, and running.
- `REVERTED`: Rolled back to original state due to regressions or deprecation.
- `FAILED`: Execution failed and was safely aborted without system corruption.

---

## 🔍 Detailed Tuning Records Template

When registering a new optimization, add a record below:

```markdown
### [T-XX]: [Title of Optimization]

- **Subsystem:** [memory | cpu | storage | network | systemd | desktop]
- **Applied Date:** YYYY-MM-DD
- **Target File(s):** `/etc/sysctl.d/99-custom.conf`, `/etc/systemd/system/...`
- **Pre-Change Backup:** `.backups/YYYYMMDD_HHMMSS-<slug>/`
- **Apply Script:** `scripts/apply-<slug>.sh`
- **Revert Script:** `scripts/revert-<slug>.sh`
- **Status:** APPLIED | REVERTED

#### Rationale & Hypothesis
[Why this change improves workstation performance, responsiveness, or resource usage.]

#### Symmetrical Scripts
- **Apply Command:** `sudo ./scripts/apply-<slug>.sh`
- **Revert Command:** `sudo ./scripts/revert-<slug>.sh`

#### Verification & Benchmarks
- **Pre-Run Summary:** `benchmarks/runs/<timestamp>-<slug>-pre/summary.json` (or baseline)
- **Post-Run Summary:** `benchmarks/runs/<timestamp>-<slug>-post/summary.json`
- **Before:** [e.g. Boot time 14.2s, latency avg=18.4us, swappiness=60]
- **After:** [e.g. Boot time 9.8s, latency avg=4.2us, swappiness=15]
- **Invariant Check:** Network, audio, and display session validated.
```
