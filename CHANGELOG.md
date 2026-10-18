# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
