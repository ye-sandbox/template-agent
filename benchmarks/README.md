# Host Benchmarks & Telemetry Harness

This directory provides a standardized, reproducible harness for measuring host performance, scheduling latency, storage throughput, and hardware thermals before and after applying optimizations.

---

## 🏛️ 3-Tier Architecture

To balance reproducible performance auditing with clean Git hygiene and AI token efficiency, the harness operates across three distinct tiers:

```
benchmarks/
├── scripts/          # Tier 1: Version-controlled, reproducible measurement scripts
│   ├── bench-cpu.sh        # CPU multithreaded / prime benchmark
│   ├── bench-io.sh         # Storage random / sequential I/O throughput
│   ├── bench-latency.sh    # Scheduling latency & timer jitter
│   └── monitor-thermals.sh # Hardware sensor, clock & temperature snapshot
├── runs/             # Tier 2: Local raw execution artifacts (IGNORED in .gitignore)
│   └── YYYYMMDD_HHMMSS-<slug>/
│       ├── raw.log         # Raw stdout/stderr of benchmark tooling
│       └── summary.json    # Key extracted indicators (P50, P99, max, throughput)
└── .agent/           # Tier 3: Versioned synthesis in Markdown
    ├── BASELINE.md         # Canonical initial host baseline scores
    └── TUNINGS.md          # Before/After deltas per tuning record [T-XX]
```

---

## 🚀 Available Benchmark Runners

| Script | Primary Tool | Fallback / Diagnostic | Metrics Captured |
|---|---|---|---|
| [`bench-cpu.sh`](./scripts/bench-cpu.sh) | `sysbench cpu` | Kernel `/proc/cpuinfo` + compute loop | Events/sec, execution time |
| [`bench-io.sh`](./scripts/bench-io.sh) | `fio` | Non-destructive `dd` (temp file) | Write MB/s, latency, IOPS |
| [`bench-latency.sh`](./scripts/bench-latency.sh) | `cyclictest` | High-res sleep timer / ping jitter | Max latency (\$\mu\$s), jitter, scheduling delay |
| [`monitor-thermals.sh`](./scripts/monitor-thermals.sh) | `sensors` / `turbostat` | `/sys/class/thermal/` & `/sys/devices/system/cpu/` | Core temperatures (°C), throttling flags |

---

## 🛠️ Usage Guidelines

1. **Running a Benchmark:**
   ```bash
   ./benchmarks/scripts/bench-cpu.sh
   ./benchmarks/scripts/bench-io.sh
   ./benchmarks/scripts/bench-latency.sh
   ./benchmarks/scripts/monitor-thermals.sh
   ```
2. **Output Location:**
   Every runner automatically writes raw logs and a structured `summary.json` into `benchmarks/runs/<timestamp>-<slug>/`.
3. **Recording in Agent Registries:**
   Do NOT commit raw logs to git. Instead, extract the summarized scores (`P50`, `P99`, `max`, `throughput`) into:
   - [`.agent/BASELINE.md`](../.agent/BASELINE.md) for initial host onboarding.
   - [`.agent/TUNINGS.md`](../.agent/TUNINGS.md) under `#### Verification & Benchmarks` when validating a tuning `[T-XX]`.

---

## 📡 Continuous Observability (Vector + VictoriaLogs)

In addition to local raw runs, the harness supports non-intrusive metric streaming directly to a centralized **VictoriaLogs** cluster via **Vector**'s HTTP ingestion endpoint (`/logs`).

### Architecture & Opt-In Configuration

Telemetry streaming is strictly **opt-in** and disabled by default (`VECTOR_ENABLED=false`). When enabled, benchmark runners automatically invoke [`benchmarks/scripts/stream-telemetry.sh`](./scripts/stream-telemetry.sh) to forward NDJSON events using short, non-blocking HTTP POST requests (`|| true`).

To activate streaming, copy `.env.example` to `.env` and set:

```bash
VECTOR_ENABLED=true
VECTOR_HOST=127.0.0.1
VECTOR_HTTP_PORT=8686
SERVICE_NAME=baremetal-workstation
ENV=production
```

### Canonical NDJSON Contract

Events emitted by the harness conform strictly to the standard structured NDJSON observability schema:

```json
{
  "timestamp": "2026-10-17T15:00:00Z",
  "service": "baremetal-workstation",
  "app": "baremetal-tuning",
  "env": "production",
  "level": "info",
  "message": "Hardware thermals and clocks snapshot on my-host",
  "metric_type": "thermals",
  "max_cpu_temp_c": 54.2,
  "avg_cpu_freq_mhz": 3400,
  "hostname": "my-host"
}
```

*Note:* If hardware thermals exceed critical throttling thresholds (`max_cpu_temp_c >= 85`) or timer latency spikes (`max_latency_us >= 500`), runners automatically elevate the event level to `warn`.

### Ready-to-Run LogsQL Query Recipes

Operators and AI agents can query live telemetry in VictoriaLogs or via VictoriaLogs MCP tools:

- **Filter all thermal snapshots:**
  ```logsql
  service:baremetal-workstation metric_type:thermals
  ```
- **Filter thermal throttling or scheduling latency warnings:**
  ```logsql
  service:baremetal-workstation level:warn
  ```
- **Find scheduling latency spikes exceeding 100 microseconds:**
  ```logsql
  service:baremetal-workstation metric_type:latency max_latency_us:>100
  ```
- **Find elevated CPU temperatures above 85°C:**
  ```logsql
  service:baremetal-workstation metric_type:thermals max_cpu_temp_c:>85
  ```
- **Track median and max latency trends over time:**
  ```logsql
  service:baremetal-workstation metric_type:latency | stats avg(avg_latency_us) by (_time:5m)
  ```
