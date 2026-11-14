# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2026-11-13

### Added

- Sequential sub-task batching (`[BATCH: Bx]`) for 2–4 same-layer subtasks anchored to untracked `.agent/scratch/specs/XX-YY.md` files, with isolated worktree propagation in `.github/scripts/bootstrap-worktree.sh` and `verify-batches` enforcement in `.github/scripts/verify-microcontract.sh`.
- Explicit Blast Radius & Mutation Boundary and Hermetic Skills & Context Contract across hub governance and all five starter branches (`greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`), enforced by `.github/scripts/check-branch-drift.sh` and `.github/scripts/test-branch-drift.sh`.
- Opt-in `--include-interface-contracts` migration installs the canonical interface skill, shared Invariants 7.1–7.4, and runtime-aware AGENTS context/DoD directives after conflict and path preflight.
- Disposable migration fixtures cover preservation, dry-run, repeat application, custom-contract conflicts, unsafe paths, and interface audit compliance through the existing self-test entry point on the Ubuntu/macOS CI matrix.
- Adaptive interface verification contracts and the on-demand `interface-testing` skill on all five starters, including Brownfield injection in standard and stealth modes.
- Ecosystem governance auditing and migration tools with heuristic compliance reports, dry-run previews, and hermetic self-tests.
- Automated interface skill and Invariant 7 drift detection, generated-project assertions, and disposable-ref regression tests integrated into the combined starter suite.

### Changed

- Hardened `classify_task_layer()` in `.github/scripts/verify-microcontract.sh` to recognize generic backend paths (`api/`, `handlers/`, `domain/`, `db/`, `models/`, `server/`, `*.py`, `*.go`, `*.rs`, etc.) and reject mixed backend/UI `Type: code` batches while keeping frontend-only helper batches valid.
- Ecosystem audit reports now check canonical interface skill bytes, shared invariants, and active context/DoD directives; the existing 100-point rubric plus 20 interface points is normalized to 0–100 (83 for a legacy-perfect project without interface contracts).
- English and Portuguese tooling documentation now describes repository selection, audit outputs and thresholds, default versus opt-in migration, preservation, conflict recovery, sequential batching, and hermetic skills contracts.

### Fixed

- Legacy ADR consolidation now preserves nested Markdown decisions and distinct content sharing a title, verifies diary writes before cleanup, and retains source trees containing unsupported assets or unsafe/unreadable entries with diagnostics.
- Opt-in interface conflicts leave the affected repository unchanged and return CLI status `1`, preserving custom invariants and failure thresholds without changing default migration behavior.
- Gateway alias validation now compares each branch's declared `.env.example` aliases against its NOTES routing row, accepting current hub defaults without requiring starter migrations.
- English README gateway defaults now match `main` and the Portuguese configuration table (`hydra-llm-router`, `fast`, `deep`).

## [1.3.0] - 2026-11-07

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
- **Hermetic Ephemeral Container & Bubblewrap Sandbox Specifications**:
  - Dual-tier sandbox architecture specifications (`Tier 1: Bubblewrap` with user/PID/IPC/net unsharing and read-only system mounts; `Tier 2: Rootless Container` with `cap-drop=ALL` and air-gapped network isolation) in `docs/agent-sandbox.md`.
- **Pre-Execution Security Scanner & Command Blast-Radius Audit Runner (`audit-command-security.sh`)**:
  - Dedicated CLI tool `.github/scripts/audit-command-security.sh` providing deterministic static command analysis for hazardous tokens (`sudo`, root mutations, unapproved network exfiltration, destructive Git operations, reverse shells, and fork bombs).
  - Integrated into `verify-microcontract.sh` to audit subagent `Verify:` commands prior to worktree execution, and into GitHub Actions CI pipeline.
- **Worktree Fast-Link Bootstrap & Lifecycle Hook Runner (`bootstrap-worktree.sh`)**:
  - Dedicated CLI tool `.github/scripts/bootstrap-worktree.sh` automating zero-copy dependency symlinking (`node_modules/`, `.venv/`), isolated `.env` injection, private scratch space provisioning (`.agent/scratch/`), and project lifecycle hook execution with hermetic self-tests.
- **Project Lifecycle Hook Standards (`.agent/hooks/`)**:
  - Standardized agent lifecycle hooks across starter templates (`post-worktree-create`, `pre-verify`, `post-worktree-teardown`) with exported environment variables, fail-safe halting, and integration into `verify-microcontract.sh`.
- **Automated CLI Flag & Scaffolding Test Suite**:
  - Automated parameter validation matrix in `.github/scripts/test-all-starters.sh` asserting `-h`, `--help`, `-f`, `--force`, `--yes`, `--standalone`, and `--local-only` flags across all 5 starter templates.
  - Cross-platform CI verification matrix across Ubuntu (`ubuntu-latest`) and macOS (`macos-latest`).
- **LLM Gateway & Virtual Model Routing Specifications (`docs/llm-gateway.md`)**:
  - Canonical OpenAI v1 compatible gateway integration architecture (`/v1/chat/completions`, `/v1/models`) eliminating upstream provider lock-in.
  - Virtual model routing taxonomy: `free-fast` for low-latency (<1.5s) intent extraction/routing and `free-deep` for high-capacity reasoning/synthesis (up to 1M token context).
  - Docker network boundary rules: mandatory integration via external shared network `hydra_shared_net` and strict prohibition of consumer attachment to internal `hydra_ai_net`.
  - Client timeout standards (minimum 180s for deep reasoning) and minimum test token allocation (`max_tokens >= 60`) preventing reasoning token budget starvation.
- **Deterministic LLM Gateway Contract Linter & Pre-Flight Probe Runner (`verify-llm-contract.sh`)**:
  - Dedicated CLI tool `.github/scripts/verify-llm-contract.sh` to statically audit consumer repositories for upstream provider string coupling, validate canonical `.env.example` schema, enforce Docker Compose network boundaries (`hydra_shared_net` with `external: true`), and execute HTTP pre-flight gateway health probes with graceful offline fallback.
  - Integrated into GitHub Actions CI pipeline on Ubuntu and macOS runners.

### Changed
- **5-Starter LLM Gateway Contract & Environment Parity**:
  - Synchronized canonical LLM Gateway schema variables (`LLM_BASE_URL`, `LLM_API_KEY`, `LLM_MODEL_FAST`, `LLM_MODEL_DEEP`, `LLM_TIMEOUT_SECONDS`) into `.env.example` across all 5 specialized starter branches (`greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`).
  - Synchronized active LLM Gateway and virtual model contracts into `.agent/NOTES.md` across all starters with automated byte-for-byte and contract parity checks in `.github/scripts/check-branch-drift.sh` and `assert-starter-contracts.sh`.
- **5-Starter Multi-Agent & Security Contract Parity**:
  - Synchronized `.agent/NOTES.md` across all 5 specialized starter branches (`greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`) with full subagent topology, worktree lifecycle, multi-account quota routing, and hermetic container sandbox contracts.
  - Enforced automated verification in `.github/scripts/check-branch-drift.sh` and `.github/scripts/assert-starter-contracts.sh` ensuring zero contract drift across all branches.
- **Worktree & Lifecycle Hook Parity Across Starters**:
  - Synchronized `.worktrees/` in `.gitignore` and `.agent/hooks/` across all 5 starter branches (`greenfield`, `brownfield`, `blackbox`, `infra`, `baremetal`) with automated anti-drift validation in `.github/scripts/check-branch-drift.sh` and `assert-starter-contracts.sh`.
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
