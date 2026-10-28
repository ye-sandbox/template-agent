# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Greenfield Standalone Mode**: Added `--standalone` flag to `init.sh` for single-repository projects, safely removing multi-repo ecosystem topology (`.agent/ECOSYSTEM.md`).
- **Zero-Dependency Test Runners**:
  - Replaced Node.js test harness on `baremetal` with native Bash smoke test runner (`tests/smoke.sh`).
  - Added standalone Bash smoke test runner and language-agnostic scaffolding to `blackbox`.
- **Inter-Branch Governance & Drift Auditing**:
  - Introduced `.github/scripts/check-branch-drift.sh` to enforce byte-for-byte knowledge card parity, mandatory `.gitignore` invariants, and CLI argument standardization across starter branches.
- **Onboarding Harmonization**:
  - Standardized first-turn prompt recommendations and post-scaffolding terminal output across all 5 starter installers.
- **Cross-Platform Scaffolding Matrix**:
  - Expanded GitHub Actions CI to assert starter scaffolding idempotency across both Ubuntu and macOS runners.
- **Host Operational Runbooks**:
  - Added operational runbooks directory index (`docs/host/README.md`) on `infra`.

### Changed
- **Tool-Agnostic Starter Contracts**:
  - Fully decoupled starter templates from external workspace tools and canvas sidecars into pure tool-agnostic runtime contracts.
- **Market-Grade Documentation Standard**:
  - Standardized bilingual documentation (`README.md` and `README.pt-br.md`) across all starter templates following modern technical documentation standards.
- **Observability Stack Generalization**:
  - Harmonized VictoriaLogs, Vector, and telemetry port bindings across `infra` and `baremetal` to neutral canonical starter defaults.
  - Standardized healthcheck probe log suppression to prevent periodic pings from polluting application and access logs.
- **Skills Directory Normalization**:
  - Standardized all starter skill directories under `.agent/skills/` and decoupled private organizational catalog links.
- **ADR Architecture Harmonization**:
  - Consolidated progressive architectural decision logs under `docs/adr/decisions.md` across all starters, removing residual `.agent/adr/` folders.

### Security & Sanitization
- **Full Git History Purge & Identity Neutralization**:
  - Executed safe repository-wide history purge rewriting commit authors and committers to canonical generic identity (`Antigravity Lead <lead@template-hub.internal>`).
  - Purged historical internal domains, reviewer usernames, and local workstation paths from all historical blobs and commit messages.

## [1.0.0] - 2026-10-17

### Added
- **Specialized Starter Branches**:
  - `greenfield`: Clean starter kit for new projects built from scratch.
  - `brownfield`: Template for legacy codebases with automated injection (`install.sh`) and enterprise `--local-only` stealth mode.
  - `blackbox`: Template for reverse engineering, web scrapers, automations, and closed APIs.
  - `infra`: Infrastructure-as-Code (IaC), Docker Compose orchestration, and homelab services.
  - `baremetal`: Host OS administration, workstation tuning, benchmark harnesses, and rollback-first guardrails.
- **Knowledge Architecture & Progressive Disclosure**:
  - Structured `.agent/knowledge/` cards with formal schema (`000-schema.md`) for runtime gotchas and platform cards.
  - Multi-repo ecosystem topology contract (`.agent/ECOSYSTEM.md`) across starters.
  - Canonical zero-dependency smoke test runner (`node --test`) preconfigured in starters.
- **Continuous Observability**:
  - Streaming host hardware metrics and latency telemetry to VictoriaLogs via Vector HTTP endpoint.
- **CI & Contract Assertions**:
  - Centralized starter validation script (`.github/scripts/assert-starter-contracts.sh`) ensuring idempotency and contract adherence.
  - Multi-branch CI matrix on GitHub Actions validating all starters.
