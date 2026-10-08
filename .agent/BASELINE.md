# BASELINE.md — Canonical Host Hardware & OS Inventory

> Captures the pre-tuning hardware specifications, OS parameters, and initial benchmark measurements.
> The agent MUST inspect and populate this registry before executing any optimizations.

---

## 🖥️ System Hardware Profile

| Property | Value | Detection Command |
|---|---|---|
| **CPU Architecture** | `[e.g. x86_64, 16 cores (8P + 8E)]` | `lscpu \| grep "Model name\|CPU(s):"` |
| **Physical Memory (RAM)** | `[e.g. 32 GiB DDR5-5600]` | `free -h` / `dmidecode -t memory` |
| **Swap / zram** | `[e.g. 8 GiB zram (zstd) + 4 GiB NVMe swapfile]` | `swapon --show`, `zramctl` |
| **Primary Storage** | `[e.g. 1 TB NVMe PCIe 4.0 (btrfs / ext4)]` | `lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS` |
| **GPU / Acceleration** | `[e.g. NVIDIA RTX 4070 (Driver 550.x)]` | `lspci \| grep -i vga` / `nvidia-smi` |

---

## 🐧 Operating System & Kernel Environment

| Subsystem | Baseline State | Detection Command |
|---|---|---|
| **Distribution / Version** | `[e.g. Ubuntu 24.04 LTS / Fedora 40]` | `cat /etc/os-release` |
| **Kernel Release** | `[e.g. 6.8.0-45-generic]` | `uname -r` |
| **Init System / PID 1** | `systemd` | `ps -p 1 -o comm=` |
| **Desktop Environment** | `[e.g. GNOME 46 (Wayland)]` | `echo $XDG_CURRENT_DESKTOP ($XDG_SESSION_TYPE)` |
| **Audio Server** | `[e.g. PipeWire 1.0.x with WirePlumber]` | `pactl info \| grep "Server Name"` |
| **Network Manager** | `[e.g. NetworkManager / systemd-networkd]` | `systemctl is-active NetworkManager` |

---

## ⚙️ Baseline Kernel & Memory Parameters

| Parameter | Initial Baseline | Target Optimization | Rationale |
|---|---|---|---|
| `vm.swappiness` | `[e.g. 60]` | `[e.g. 10–20]` | Delay swap usage until memory pressure is severe |
| `vm.vfs_cache_pressure` | `[e.g. 100]` | `[e.g. 50]` | Retain directory inode/dentry cache longer in RAM |
| `vm.dirty_ratio` | `[e.g. 20]` | `[e.g. 10]` | Trigger background dirty writeouts earlier |
| `vm.dirty_background_ratio` | `[e.g. 10]` | `[e.g. 5]` | Smooth disk I/O bursts during heavy writes |
| `fs.file-max` | `[e.g. 9223372036854775807]` | - | Global system file descriptor limit |
| `I/O Scheduler` | `[e.g. none (NVMe), bfq (SATA)]` | `[e.g. none / mq-deadline]` | `cat /sys/block/nvme0n1/queue/scheduler` |

---

## ⏱️ Initial Baseline Benchmarks

> Execute `./benchmarks/scripts/<script>.sh` to collect baseline measurements.
> Raw execution dumps are saved to local `benchmarks/runs/` (gitignored). Record summarized indicators below.

| Metric | Baseline Score | Measurement Method / Harness Command |
|---|---|---|
| **Cold Boot Time** | `[e.g. 12.4s (kernel 3.1s, userspace 9.3s)]` | `systemd-analyze` |
| **Top Slow Services** | `[e.g. plymouth-quit-wait.service (2.1s)]` | `systemd-analyze blame \| head -n 5` |
| **Memory Pressure (PSI)** | `[e.g. some avg10=0.00 avg60=0.00]` | `cat /proc/pressure/memory` |
| **CPU Benchmark** | `[e.g. 1540.2 events/sec, 12.98s]` | `./benchmarks/scripts/bench-cpu.sh` |
| **Disk Write Throughput** | `[e.g. 1.8 GB/s (fio randwrite / dd)]` | `./benchmarks/scripts/bench-io.sh` |
| **Scheduling Latency** | `[e.g. avg 4.2us, max 18.0us]` | `./benchmarks/scripts/bench-latency.sh` |
| **Hardware Thermals / Clocks** | `[e.g. max 58.0°C, avg 4200 MHz]` | `./benchmarks/scripts/monitor-thermals.sh` |

---

## Notes & Audit Log

- Baseline captured on initial onboarding.
- Re-run benchmarks whenever major kernel updates or hardware changes occur.
