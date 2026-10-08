# INVARIANTS.md — Host Invariants & Chesterton's Fences

> Critical host subsystems, network interfaces, and essential services that MUST NEVER be broken or disabled.
> 
> 💡 **Chesterton's Fence Principle:** Never remove or disable a service, daemon, or kernel parameter until you fully understand why it was put there in the first place.

---

## 🛡️ Host Stability Invariants

The agent MUST verify that any proposed optimization strictly preserves these operational boundaries:

### 1. Network & Connectivity
- Primary network interface MUST maintain stable IPv4/IPv6 leases.
- DNS resolution (`systemd-resolved` or `/etc/resolv.conf`) MUST NOT be interrupted.
- Firewall rules (`ufw`, `iptables`, `nftables`) MUST NOT drop active SSH sessions or local LAN discovery unless explicitly requested.

### 2. Display Server & Desktop Environment
- Wayland / X11 compositor (Mutter, KWin, Sway, Hyprland) MUST NOT be killed or uninstalled.
- GPU proprietary/open drivers (NVIDIA kernel modules, Mesa, VA-API) MUST remain loadable.
- Display manager (`gdm`, `sddm`, `lightdm`) service state MUST NOT be disabled without explicit confirmation.

### 3. Audio & Media Pipeline
- PipeWire / WirePlumber / PulseAudio audio routing MUST remain intact.
- Bluetooth audio daemon (`bluez`) must not be terminated if wireless peripherals are paired.

### 4. Storage & Filesystem Integrity
- Root partition (`/`) mount flags in `/etc/fstab` MUST NOT be altered without pre-boot verification.
- Swap partition or swapfile must never be deleted without an active zram or alternate swap allocation.
- Do NOT disable journald logs completely — rotate or cap size (`SystemMaxUse=500M`) instead.

### 5. Bootloader & Kernel Recovery
- The currently running kernel MUST NOT be purged before a newer tested kernel is verified working.
- GRUB or systemd-boot timeout MUST remain $\ge 2\text{s}$ to allow boot menu rescue.
- Never edit `/boot/grub/grub.cfg` manually; modify `/etc/default/grub` and run `grub-mkconfig`.

---

## 🚫 Blacklisted Operations (Never Perform Autonomously)

| Prohibited Command / Action | Risk / Consequence | Approved Safe Alternative |
|---|---|---|
| `sudo rm -rf /etc/...` | Irreversible loss of system configuration | Move to `.backups/<timestamp>/` |
| `sudo apt purge systemd*` | Destroys OS init system | Disable individual non-essential unit |
| `echo 0 > /proc/sys/vm/swappiness` | Can trigger OOM kills on memory spikes | Set low safe swappiness (e.g. `10` or `15`) |
| `sudo systemctl disable NetworkManager` | Immediate loss of network connectivity | Tune timeout or optimize interface flags |
| `sudo dd if=... of=/dev/sdX` | Catastrophic partition wipe | Use high-level filesystem utilities |

---

## Verification Checklist Before Committing Changes

Before any optimization is considered complete:
- [ ] Network ping works: `ping -c 2 1.1.1.1` and `curl -I https://www.google.com`
- [ ] Audio daemon is active: `pactl info`
- [ ] Desktop session is responsive: `loginctl show-session $(loginctl \| awk 'NR==2{print $1}')`
- [ ] Storage mounts verified: `mount -a --test` or `findmnt --verify`
