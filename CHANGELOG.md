# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Multi-Agent Subagent Topology & Micro-Contracts**:
  - Formal 3-tier subagent hierarchy (`Lead / Orchestrator`, `Worker / Implementer`, `Reviewer / Sentinel`) with isolated responsibility boundaries in `docs/subagent-topology.md`.
  - Micro-contract standard (`Role:`, `Task:`, `Isolation:`, `Read:`, `Paths:`, `Verify:`) for strict blast radius containment.
- **Git Worktree Isolation & Dependency Lifecycle**:
  - Deterministic 6-stage worktree lifecycle protocol in `docs/worktree-isolation.md`.
  - Heuristic dependency bootstrap strategy: Fast-Link (<50ms symlink for static manifests) vs. Isolated-Install (clean worktree install for manifest diffs), plus safe `.env` injection and guaranteed garbage collection.
- **Deterministic Micro-Contract & Worktree Linter (`verify-microcontract.sh`)**:
  - Dedicated CLI tool `.github/scripts/verify-microcontract.sh` to validate micro-contracts, detect disjoint-file conflicts in parallel execution waves (`[PARALLEL: Wx]`), and verify git worktree blast boundaries and whitespace hygiene.
  - Integrated into GitHub Actions CI pipeline and starter validation suites.
- **Pre-Execution Security Scanner & Command Blast-Radius Audit Runner (`audit-command-security.sh`)**:
  - Dedicated CLI tool `.github/scripts/audit-command-security.sh` providing deterministic static command analysis for hazardous tokens (`sudo`, root mutations, unapproved network exfiltration, destructive Git operations, reverse shells, and fork bombs).
  - Integrated into `verify-microcontract.sh` to audit subagent `Verify:` commands prior to worktree execution, and into GitHub Actions CI pipeline.
- **Automated CLI Flag & Scaffolding Test Suite**:
  - Automated parameter validation matrix in `.github/scripts/test-all-starters.sh` asserting `-h`, `--help`, `-f`, `--force`, `--yes`, `--standalone`, and `--local-only` flags across all 5 starter templates.
  - Cross-platform CI verification matrix across Ubuntu (`ubuntu-latest`) and macOS (`macos-latest`).

### Changed
- **5-Starter Multi-Agent Contract Parity**:
  - Synchronized `.agent/NOTES.md` across all 5 specialized starter branches (`greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`) with full subagent topology, worktree lifecycle, and multi-account quota routing contracts.
  - Resolved all inter-branch contract drift in `.github/scripts/check-branch-drift.sh`.
- **Multi-Account Quota Failover Guidance**:
  - Standardized quota floor circuit breaker (disqualification at <=5% remaining), secondary account priority via `select-profile.sh --exclude-current`, default `gemini-3.8-flash-medium` tier, 429 cooldown tracking, and clean worktree diff recovery on timeout.

## [1.2.0] - 2026-11-05

### Added
- **Pre-Approved Task Fast-Track (`Status: APPROVED`)**:
  - Direct transition from planning to `RUNNING` on `proceed` for pre-approved scopes without redundant interactive approval pauses.
- **Parallel Task Waves & Multi-Account Quota Routing**:
  - Support for parallel wave execution tags (`[PARALLEL: Wx]`) and multi-account quota balancing via the `task-queue` skill.
- **Token-Efficient Wave Runner (`run-wave.sh`)**:
  - Micro-contract standard (`Read:`, `Paths:`, `Verify:`) and CLI wave runner defaulting to `gemini-3.8-flash-medium` for subagent execution.

### Changed
- **Circuit Breaker Threshold Calibration**:
  - Calibrated fail-stop threshold to 3 consecutive identical failures on general starters (`main`, `greenfield`, `brownfield`) and 2 consecutive failures on sensitive environments (`blackbox`, `infra`, `baremetal`).
- **High-Density `AGENTS.md` Specification**:
  - Full audit and refactoring of `AGENTS.md` across the Hub and all 5 starter branches (`greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`) using the `agent-doc-refactor` framework.
  - Introduced strict priority hierarchy (`[P0]` Security to `[P3]` Style), modular progressive disclosure triggers, fail-stop escalation payloads, and positive/negative contrast pairs.
- **ADR Architecture Consolidation**:
  - Single Source of Truth for architectural decisions codified strictly in `docs/adr/decisions.md`.
  - Enforced ban on task-specific headings (`## [Task XX.Y]`) in `NOTES.md` to prevent dual-source drift.
- **Knowledge Base Definition of Done (DoD) Guardrail**:
  - Enforced invariant that `.agent/knowledge/` cards capture strictly reproducible platform/runtime gotchas, explicitly prohibiting application features or business logic.

## [1.1.0] - 2026-10-28

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
