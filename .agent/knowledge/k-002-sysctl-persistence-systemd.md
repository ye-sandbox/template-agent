---
id: "k-002"
title: "Sysctl Kernel Parameter Persistence via sysctl.d and Systemd Service Overrides"
date: 2026-10-19
tags:
  - "linux"
  - "kernel"
  - "sysctl"
  - "systemd"
  - "baremetal"
  - "persistence"
severity: "high"
affected_components:
  - ".agent/TUNINGS.md"
  - "/etc/sysctl.d/"
  - "/etc/systemd/system/"
symptoms:
  - "sysctl values reset to defaults after reboot"
  - "network tuning parameters overwritten by NetworkManager or systemd-sysctl"
  - "systemd service limits revert after package upgrade"
---

# [k-002] Sysctl Kernel Parameter Persistence via sysctl.d and Systemd Service Overrides

## Problem / Symptom

Applying runtime kernel tunings via `sysctl -w key=value` or running temporary resource limit adjustments via `ulimit` does not survive host reboots or service reloads. Furthermore:
- Placing tunings directly into `/etc/sysctl.conf` can be preempted or overridden on modern Linux distributions by higher-precedence drop-ins located in `/run/sysctl.d/` or `/usr/lib/sysctl.d/`.
- Editing upstream systemd service unit files directly in `/lib/systemd/system/` causes all custom resource tunings (`LimitNOFILE`, `CPUQuota`, `MemoryMax`) to be wiped out whenever the package is updated.

## Approved Solution

Always persist host system tunings using isolated, high-precedence configuration drop-in files:

1. **Kernel Sysctl Persistence via `/etc/sysctl.d/`:**
   Create an isolated tuning file with a high numerical prefix (e.g., `99-custom.conf`) in `/etc/sysctl.d/`:

   ```bash
   # INVARIANT: Backup existing configuration before writing
   mkdir -p /etc/sysctl.d
   cat << 'EOF' > /etc/sysctl.d/99-workstation-tunings.conf
   # Network buffer enhancements
   net.core.rmem_max = 16777216
   net.core.wmem_max = 16777216
   net.ipv4.tcp_rmem = 4096 87380 16777216
   net.ipv4.tcp_wmem = 4096 65536 16777216

   # Virtual memory swapping threshold
   vm.swappiness = 10
   vm.vfs_cache_pressure = 50
   EOF

   # Apply immediately without rebooting
   sysctl --system
   ```

2. **Systemd Service Overrides via Drop-In Snippets:**
   Never edit `/lib/systemd/system/<service>.service` directly. Use `systemctl edit <service>` or create a dedicated drop-in directory:

   ```bash
   mkdir -p /etc/systemd/system/<service>.service.d/
   cat << 'EOF' > /etc/systemd/system/<service>.service.d/override.conf
   [Service]
   LimitNOFILE=65536
   LimitNPROC=32768
   EOF

   systemctl daemon-reload
   systemctl restart <service>
   ```

**Root Cause:** Modern Linux init systems (systemd) parse configuration files in a defined precedence hierarchy (`/etc/` > `/run/` > `/usr/lib/`), ordered lexicographically. Ephemeral CLI modifications affect only the running kernel memory, whereas drop-in directories ensure non-destructive persistence across upgrades and reboots.

## What NEVER to Do

- ❌ **Anti-Pattern:** Appending custom tunings to `/etc/rc.local` or executing custom sysctl scripts from root cron on `@reboot`.
  - *Why:* Bypasses systemd dependency resolution and causes race conditions with network or hardware initialization.
- ❌ **Anti-Pattern:** Modifying `/lib/systemd/system/*.service` or `/usr/lib/sysctl.d/*.conf`.
  - *Why:* Upstream package managers overwrite vendor directories without notice during system updates, reverting tunings silently.

## Verification

Check active parameters and verify they match the drop-in source:

```bash
# Verify active kernel value
sysctl net.core.rmem_max

# Test systemd drop-in override
systemctl show -p LimitNOFILE <service>
```

## References
- [systemd-sysctl.service documentation](https://www.freedesktop.org/software/systemd/man/systemd-sysctl.service.html)
- [systemd.unit drop-in documentation](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)
