---
name: baremetal-tuning
description: Standard operating procedure for safely diagnosing, benchmarking, applying, and rolling back host OS and workstation optimizations.
---

# Baremetal Tuning Skill

This skill defines the mandatory workflow for applying performance optimizations, kernel parameters, systemd service adjustments, and workstation dotfiles while guaranteeing zero catastrophic blast radius and 100% reversible rollbacks.

---

## 🔄 6-Step Reversible Tuning Lifecycle

```mermaid
graph LR
    S1[1. Baseline & Audit] --> S2[2. Invariants Check]
    S2 --> S3[3. Pre-Change Backup]
    S3 --> S4[4. Author Symmetrical Scripts]
    S4 --> S5[5. Revert Validation]
    S5 --> S6[6. Apply & Benchmark]
```

### Step 1: Baseline & Audit
- Read current parameters and record current values.
- Example:
  ```bash
  cat /proc/sys/vm/swappiness
  systemctl status <service-name>
  ```
- Record the current reading in `.agent/BASELINE.md` or `.agent/NOTES.md`.

### Step 2: Invariants Verification
- Cross-reference target files with [`.agent/INVARIANTS.md`](../../INVARIANTS.md).
- Confirm that the proposed change does NOT touch prohibited subsystems (bootloader, desktop compositor, active network interface, audio pipeline) without explicit permission.

### Step 3: Pre-Change Backup Creation
- Create a timestamped backup directory under `.backups/`:
  ```bash
  TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
  BACKUP_DIR=".backups/${TIMESTAMP}-<slug>"
  mkdir -p "$BACKUP_DIR"
  ```
- Copy any existing configuration file that will be overwritten or appended into this backup folder.
- If the file is newly introduced, document in the backup folder that original state was non-existent.

### Step 4: Author Symmetrical Scripts
Author two complementary shell scripts in `scripts/`:
1. `scripts/apply-<slug>.sh`
2. `scripts/revert-<slug>.sh`

Both scripts MUST:
- Use `set -euo pipefail`.
- Be idempotent (safe to run multiple times).
- Print clear diagnostic output upon success.

#### Canonical Script Pair Pattern:

**`scripts/apply-<slug>.sh`:**
```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR=".backups/$(date +%Y%m%d_%H%M%S)-<slug>"
mkdir -p "$BACKUP_DIR"

# Snapshot existing file if present
if [ -f "/etc/sysctl.d/99-<slug>.conf" ]; then
    cp "/etc/sysctl.d/99-<slug>.conf" "$BACKUP_DIR/"
fi

# Apply configuration
echo "vm.<param> = <new_val>" | sudo tee "/etc/sysctl.d/99-<slug>.conf" > /dev/null
sudo sysctl --system > /dev/null

echo "✅ Applied <slug> successfully. Backup at: $BACKUP_DIR"
```

**`scripts/revert-<slug>.sh`:**
```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_CONF="/etc/sysctl.d/99-<slug>.conf"

if [ -f "$TARGET_CONF" ]; then
    sudo rm -f "$TARGET_CONF"
    sudo sysctl --system > /dev/null
    echo "✅ Reverted <slug>: removed $TARGET_CONF"
else
    echo "ℹ️ Target configuration $TARGET_CONF does not exist; nothing to revert."
fi
```

### Step 5: Revert Validation
- Check script syntax:
  ```bash
  bash -n scripts/apply-<slug>.sh
  bash -n scripts/revert-<slug>.sh
  ```
- Dry-run or review revert logic to ensure it cleanly restores the pre-change state without side effects.

### Step 6: Apply, Verify & Benchmark
- Present the proposed scripts to the user and obtain execution approval.
- Execute `apply-<slug>.sh`.
- Run post-change verification:
  - Invariant assertion (network, audio, display).
  - Benchmark performance differential.
- Update status and metrics in [`.agent/TUNINGS.md`](../../TUNINGS.md).
