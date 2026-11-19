#!/usr/bin/env python3
"""
apply-governance-standards.py

Automated propagator and migration runner for ADD (Agent-Driven Development) governance standards:
  1. Single ADR Diary (docs/adr/decisions.md) & verified legacy ADR cleanup
  2. NOTES.md Sanitization (extract task headings to ARCHIVE.md, enforce heading ban)
  3. Multi-Agent Subagent Topology & Worktree/Quota Micro-Contracts in NOTES.md
  4. AGENTS.md High-Density [P0]-[P3] Precedence Matrix & Fail-Stop Protocol

Usage:
    python3 apply-governance-standards.py [ROOT_DIR] [OPTIONS]
    python3 apply-governance-standards.py --self-test

Options:
    --dir, -d PATH        Root directory to scan (default: ~/github or current dir)
    --dry-run             Simulate changes without modifying any files on disk
    --repo REPO           Apply exclusively to the specified repository name
    --exclude [REPO ...]  Repository directory names to exclude
    --no-exclude          Do not apply default exclusion filters
    --include-interface-contracts
                          Opt in to canonical skill, Invariants 7.1–7.4, and
                          runtime-aware AGENTS context/DoD directives. Custom
                          conflicts block this repository without writes (exit 1).
                          Requires this script to remain in the hub checkout with
                          the canonical skill and invariants. Omit this flag for legacy behavior.
    --include-two-tier    Opt in to 2-Tier Progressive Rigor (AGENTS.md 2-tier &
                          hermetic skills, lean TASK.md cleanup, .harness/ in
                          .gitignore, .agent/hooks/README.md, and hydra-llm-router
                          .env.example alignment). Omit for legacy behavior.
    --all-standards       Enable both --include-interface-contracts and
                          --include-two-tier.
    --self-test           Run hermetic unit and verification test suite

Opt-in example (preview first):
    python3 apply-governance-standards.py /path/to/project --all-standards --dry-run
    python3 apply-governance-standards.py /path/to/project --all-standards

Dry-run writes nothing. Reapplying complete contracts produces no changes.
Conflicts require manual reconciliation at the diagnostic path, then a retry.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path
from typing import List, Set

IGNORED_DIR_NAMES = {
    "node_modules", ".venv", "venv", ".git", ".worktrees", "tmp",
    "cache", ".cache", "dist", "build", "target", "vendor",
    ".system_generated", ".gemini", ".claude", "__pycache__"
}

DEFAULT_EXCLUDED_NAMES = {
    "template-agent", "agent-skills", ".github", "yegear1", "org-ye-sandbox"
}

CANONICAL_MULTI_AGENT_CONTRACT = """### Multi-Agent Collaboration Contracts

> Canonical 3-tier subagent topology, Tier 2 (`dev-harness`) micro-contracts, worktree isolation, and hermetic sandboxes.

| Role | Interface / Channel | Responsibilities | Boundary & Invariants |
|---|---|---|---|
| **`Lead / Orchestrator`** | `.agent/TASK.md` / Interactive Prompt | Decomposes initiatives into tasks, manages task lifecycle, routes to model/quota tiers, interacts with human. | Sole manager of `TASK.md` and commit log. Does not run parallel worker tasks directly. |
| **`Worker / Implementer`** | Worktree / Target Workspace | Executes atomic code/doc changes strictly adhering to delegated micro-contract (`files_read`, `files_edit`, `verify`). | Restricted exclusively to `files_edit`. Adheres to DoD in `AGENTS.md`. |
| **`Reviewer / Sentinel`** | Diffs / Test Harness (`verify`) | Read-only inspection of diffs against task DoD, regression tests, and security blast radius. | Read-only; reports structured Pass/Fail diagnostic payload. |

#### Worktree Isolation & Dependency Bootstrap Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Workspace Provisioning** | `git worktree add -b task-<id> <path> HEAD` | Default ephemeral path (`${TMPDIR:-/tmp}/worktrees/task-<id>`) or `.worktrees/task-<id>` (`.worktrees/` in `.gitignore`). |
| **Dependency Bootstrap** | Fast-Link vs. Isolated-Install | Fast-Link (symlink `node_modules/` or `.venv/`) when `files_edit` has no manifest changes (<50ms, zero-copy). Isolated-Install when manifests change. |
| **Environment Injection** | Copy `.env` / `.env.example` to worktree | Ensures test harness execution without leaking uncommitted tokens or mutating root config. |
| **Teardown & GC** | `git worktree remove --force` + `branch -D` + `prune` | Immediate cleanup post-integration; trap declared in runners to prevent dangling worktree locks. |

#### Project Lifecycle Hooks & Fast-Link Bootstrap Contract

| Hook / Phase | Script Target | Invocation & Contract |
|---|---|---|
| **Fast-Link Bootstrap** | `bootstrap-worktree.sh` | Zero-copy symlinking of `node_modules/` and `.venv/`, `.env` isolation copy, and `.agent/scratch/` provisioning. |
| **Post-Provisioning** | `.agent/hooks/post-worktree-create` | Executed post-bootstrap for test DB seeding, port binding, and ephemeral fixtures. Halts on non-zero exit. |
| **Pre-Verification** | `.agent/hooks/pre-verify` | Executed before `verify` command execution to ensure clean test state and fixture validation. |
| **Post-Teardown** | `.agent/hooks/post-worktree-teardown` | Executed prior to worktree removal (`git worktree remove`) for graceful daemon/resource teardown. |

#### Multi-Account Quota Routing & Failover Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Profile Routing Priority** | `select-profile.sh --exclude-current` | Autonomous workers route to secondary accounts with highest quota; active IDE profile reserved for Lead Orchestrator. |
| **Quota Floor Circuit Breaker** | `remaining_fraction <= 0.05` | Immediate disqualification of profiles with <=5% quota; halts execution if all candidate profiles are below floor. |
| **Model Tier Selection** | `default-tier` / `escalation-tier` (mapped via `WORKER_MODEL_DEFAULT_TIER` / `WORKER_MODEL_ESCALATION_TIER`) | Low token footprint default; escalation to `escalation-tier` permitted only for complex architecture or max 1 retry after verification failure. |
| **Cooldown Tracking** | `<profile>/.multigravity/quota-history.jsonl` | 429 rate limit backoff and cooldown persistence to prevent immediate re-dispatch. |
| **Worktree Recovery** | Worktree verify on timeout | Runs `verify` inside worktree on timeout; if code 0 and matches `files_edit`, recovers diff cleanly. |

#### Hermetic Agent Sandbox & Container Isolation Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Tier 1 (Bubblewrap)** | `bwrap --unshare-all --ro-bind /usr ...` | Rootless user namespace, read-only system binaries, ephemeral tmpfs `/tmp`, worktree read-write bind, `--die-with-parent`. |
| **Tier 2 (Rootless Container)** | `podman run --read-only --cap-drop=ALL` | Rootless OCI container, read-only rootfs, `no-new-privileges`, memory (2G) and CPU (2.0) limits, tmpfs `/tmp` with `noexec`. |
| **Network Namespacing** | `--unshare-net` / `--network none` | Hermetic air-gap by default; egress permitted exclusively for explicit external API or dependency fetching tasks. |
| **Fallback & Escalation** | `audit-command-security.sh` | Static pre-execution audit for hazardous commands (`sudo`, `/etc` writes, curl pipes) when namespaces unavailable. |

#### LLM Gateway & Virtual Model Routing Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **API Protocol** | OpenAI v1 (`/v1/chat/completions`, `/v1/models`, `/v1/hydra/models`) | Standard JSON schema, streaming SSE, tool calling via `hydra-llm-router`; discover operator-configured virtual aliases via `/v1/models` or `/v1/hydra/models` with zero provider-specific SDK lock-in. |
| **Virtual Model Routing** | `fast` vs. `deep` | Operator-configured virtual aliases (`fast` default for low-latency <1.5s intent/extractions; `deep` opt-in for complex reasoning/synthesis up to 1M tokens). |
| **Network Isolation** | `hydra_shared_net` (`external: true`) | Co-located sibling containers join `hydra_shared_net` for direct DNS `http://hydra-llm-router:3000/v1` (external hosts use `https://hydra-router.homelab.yegear.dev/v1`). Joining `hydra_router_internal` or legacy `hydra_ai_net` is strictly forbidden. |
| **Client Timeout & Budget** | `LLM_TIMEOUT_SECONDS >= 180` | Minimum 180s timeout for deep reasoning calls; minimum `max_tokens >= 60` on test probes to prevent empty completions caused by reasoning token consumption. |
"""

FAIL_STOP_SECTION = """## Fail-Stop Protocol & Escalation Hierarchy

If an automated command or build step fails **3 consecutive times** with the same root cause:
1. Halt execution immediately.
2. MUST NOT attempt unapproved workarounds.
3. Escalate to the human operator with a structured diagnostic payload:
```yaml
failure_stage: "<command or step name>"
error_signature: "<exact error string>"
consecutive_failures: 3
root_cause_analysis: "<technical root cause>"
attempted_fixes:
  - "<attempt 1>"
  - "<attempt 2>"
  - "<attempt 3>"
pending_decision: "<clarification or choice required from human>"
```
"""

CONTRAST_PAIRS_SECTION = """## Contrast Pairs

### Commit Messages
```markdown
// BAD: Combining multiple concerns, vague or past-tense message
git commit -m "fixed stuff, updated docs and updated init.sh"

// GOOD: Single atomic change with RFC-compliant imperative verb
git commit -m "fix(installer): resolve remote execution flag parsing"
```

### Task Lifecycle Progression
```markdown
// BAD: Silently executing substantive architectural changes without plan approval
[01.6] Directly edited 10 files without presenting a plan

// GOOD: Standard Plan-First progression
[01.6] Present plan -> Human Approval -> execute `- [ ]` checklist -> verify -> atomic commit
```
"""

TWO_TIER_AGENTS_SECTION = """## 2-Tier Execution & Hermetic Skills Contract

- **Tier 1 — Interactive (Default):** Lean `.agent/TASK.md` checklist (`- [ ]` atomic subtasks) validated by the repository's canonical test and build commands.
- **Tier 2 — Autonomous (`dev-harness` / Parallel Worktrees):** Strict micro-contracts (`files_read`, `files_edit`, `verify`) live inside `.harness/queue/<id>.{md,yaml}` or `harness:ready` GitHub Issues consumed by `dev-harness`, never in `.agent/TASK.md`. Lifecycle hooks in `.agent/hooks/` (`post-worktree-create`, `pre-verify`, `post-worktree-teardown`) apply to both tiers.
- **Hermetic Skills & Context Contract:** Procedural guidelines and skills must be self-contained within `.agent/skills/` or injected directly into the task dispatch prompt by the orchestrator; never wander the host filesystem for missing skills.
"""

GITIGNORE_INVARIANTS = [
    ".agent/scratch/",
    ".agent/.cache/",
    ".worktrees/",
    ".maestri/",
    ".multigravity/",
    ".harness/queue/done/",
    ".harness/queue/escalated/",
    ".harness/worktrees/",
]


def find_git_repos(root_dir: Path, max_depth: int = 4) -> List[Path]:
    """Recursively discover unique git repository roots up to max_depth."""
    repos: List[Path] = []
    seen_paths: Set[Path] = set()

    root_dir = root_dir.resolve()
    if not root_dir.exists():
        return repos

    git_marker = root_dir / ".git"
    if git_marker.exists():
        return [root_dir]

    def _scan(current: Path, depth: int):
        if depth > max_depth:
            return
        try:
            entries = list(os.scandir(current))
        except (PermissionError, FileNotFoundError):
            return

        is_git = False
        subdirs: List[Path] = []

        for entry in entries:
            if entry.name in IGNORED_DIR_NAMES and entry.name != ".git":
                continue
            if entry.name == ".git" and (entry.is_dir() or entry.is_file()):
                is_git = True
            elif entry.is_dir(follow_symlinks=False):
                subdirs.append(Path(entry.path))

        if is_git:
            resolved = current.resolve()
            if resolved not in seen_paths:
                seen_paths.add(resolved)
                repos.append(resolved)
            return

        for s in sorted(subdirs):
            _scan(s, depth + 1)

    _scan(root_dir, 1)
    return sorted(repos)


ADR_MARKER = re.compile(rb"(?m)^<!-- template-agent:adr sha256=([0-9a-f]{64}) bytes=([0-9]+) -->\n")
ADR_END = b"\n<!-- /template-agent:adr -->\n"


def preserved_adr_documents(content: bytes) -> set[bytes]:
    """Recognize complete documents, never title or body substrings."""
    documents = set(content.split(b"\n---\n\n"))
    documents.add(content)
    for match in ADR_MARKER.finditer(content):
        payload = content[match.end():match.end() + int(match[2])]
        end = match.end() + len(payload)
        if (
            hashlib.sha256(payload).hexdigest().encode() == match[1]
            and content[end:end + len(ADR_END)] == ADR_END
        ):
            documents.add(payload)
    return documents


def write_adr_diary(path: Path, content: bytes) -> None:
    """Replace the diary atomically; a failed write must not truncate history."""
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=".decisions-", delete=False) as handle:
            temporary = Path(handle.name)
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
        temporary.chmod(mode)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def inspect_legacy_adrs(repo: Path) -> tuple[dict[Path, bytes], list[Path], list[str]]:
    """Inventory without following symlinks or discarding undecodable bytes."""
    legacy = repo / ".agent" / "adr"
    documents: dict[Path, bytes] = {}
    directories: list[Path] = []
    blockers: list[str] = []
    if (repo / ".agent").is_symlink() or legacy.is_symlink():
        return documents, directories, [f"{legacy}: symlinked source path"]

    def visit(directory: Path) -> None:
        directories.append(directory)
        for path in sorted(directory.iterdir()):
            if path.is_symlink():
                blockers.append(f"{path}: symlink")
            elif path.is_dir():
                visit(path)
            elif not path.is_file() or path.suffix.lower() != ".md":
                blockers.append(f"{path}: unsupported non-Markdown entry")
            else:
                try:
                    payload = path.read_bytes()
                    payload.decode("utf-8")
                    documents[path] = payload
                except (OSError, UnicodeError) as error:
                    blockers.append(f"{path}: {type(error).__name__}")

    try:
        visit(legacy)
    except OSError as error:
        blockers.append(f"{legacy}: {type(error).__name__}")
    return documents, directories, blockers


def consolidate_adrs(repo: Path, dry_run: bool) -> list[str]:
    """Consolidate supported ADR trees; retain blocked trees at their original paths."""
    legacy = repo / ".agent" / "adr"
    if not legacy.exists() and not legacy.is_symlink():
        return []
    documents, directories, blockers = inspect_legacy_adrs(repo)
    diary = repo / "docs" / "adr" / "decisions.md"
    for path in [repo / "docs", diary.parent, diary]:
        if path.is_symlink():
            blockers.append(f"{path}: symlinked destination path")
    if blockers:
        return ["Blocked ADR consolidation; source retained: " + reason for reason in blockers]
    try:
        existing = diary.read_bytes() if diary.exists() else b""
        existing.decode("utf-8")
    except (OSError, UnicodeError) as error:
        blockers.append(f"{diary}: {type(error).__name__}")
        existing = b""
    if blockers:
        return ["Blocked ADR consolidation; source retained: " + reason for reason in blockers]

    result = existing
    known = preserved_adr_documents(existing) if diary.exists() else set()
    added = 0
    for payload in documents.values():
        if payload in known:
            continue
        if not result:
            result = (
                f"# Architecture Decision Records — {repo.name}\n\n"
                f"Consolidated chronological log of architectural decisions for {repo.name}.\n"
            ).encode()
        digest = hashlib.sha256(payload).hexdigest()
        marker = f"<!-- template-agent:adr sha256={digest} bytes={len(payload)} -->\n".encode()
        result += b"\n\n---\n\n" + marker + payload + ADR_END
        known.add(payload)
        added += 1
    actions = [f"Consolidated {added} distinct ADR document(s) into docs/adr/decisions.md"] if added else []
    if dry_run:
        return actions + ["Planned cleanup of verified legacy ADR files and empty directories"]

    if result != existing:
        write_adr_diary(diary, result)
    persisted = diary.read_bytes() if diary.exists() else b""
    preserved = preserved_adr_documents(persisted)
    if persisted != result or any(payload not in preserved for payload in documents.values()):
        raise OSError("ADR diary verification failed; source retained")
    # INVARIANT: Verify the whole inventory before cleanup; remove only known files.
    # New or changed content must prevent deletion, including on a retry after failure.
    current, _, current_blockers = inspect_legacy_adrs(repo)
    if current_blockers or current != documents:
        raise OSError("Legacy ADR tree changed during consolidation; source retained")
    for path, payload in documents.items():
        if path.is_symlink() or path.read_bytes() != payload:
            raise OSError(f"Legacy ADR changed before cleanup; source retained: {path}")
        path.unlink()
    for directory in reversed(directories):
        directory.rmdir()
    return actions + ["Removed verified legacy ADR files and empty directories"]


def sanitize_notes_md(repo: Path, dry_run: bool) -> List[str]:
    """Point 2: Remove task-specific headings from NOTES.md and move them to ARCHIVE.md."""
    actions: List[str] = []
    notes_file = repo / ".agent" / "NOTES.md"
    archive_file = repo / ".agent" / "ARCHIVE.md"

    if not notes_file.is_file():
        return actions

    content = notes_file.read_text(encoding="utf-8", errors="ignore")
    lines = content.splitlines()

    task_heading_regex = re.compile(
        r"^##+\s*(\[?\d{4}-\d{2}-\d{2}\]?\s*)?\[?(?:Tasks?\s+)?\d{2}\.\d+",
        re.IGNORECASE
    )

    extracted_task_blocks: List[str] = []
    clean_lines: List[str] = []
    in_task_block = False
    current_block: List[str] = []

    for line in lines:
        if task_heading_regex.match(line):
            if in_task_block and current_block:
                extracted_task_blocks.append("\n".join(current_block))
                current_block = []
            in_task_block = True
            current_block.append(line)
        elif in_task_block:
            if re.match(r"^##\s+(?!\[?(?:Task|\d{2}\.\d+))", line) and not task_heading_regex.match(line):
                in_task_block = False
                extracted_task_blocks.append("\n".join(current_block))
                current_block = []
                clean_lines.append(line)
            else:
                current_block.append(line)
        else:
            clean_lines.append(line)

    if in_task_block and current_block:
        extracted_task_blocks.append("\n".join(current_block))

    if extracted_task_blocks:
        actions.append(f"Extracted {len(extracted_task_blocks)} task-specific heading blocks from NOTES.md")
        if not dry_run:
            archive_content = ""
            if archive_file.is_file():
                archive_content = archive_file.read_text(encoding="utf-8", errors="ignore")
            archive_append = "\n\n## Migrated Tasks from NOTES.md\n\n" + "\n\n".join(extracted_task_blocks)
            archive_file.write_text(archive_content.rstrip() + archive_append + "\n", encoding="utf-8")
        actions.append("Archived extracted task blocks into .agent/ARCHIVE.md")

        clean_notes = "\n".join(clean_lines)
        if not dry_run:
            notes_file.write_text(clean_notes, encoding="utf-8")
        actions.append("Sanitized NOTES.md (removed task headings)")

    # Ensure critical invariant heading ban is present in NOTES.md
    invariant_text = "NEVER create task-specific headings"
    current_notes_content = notes_file.read_text(encoding="utf-8", errors="ignore") if notes_file.is_file() else ""
    if invariant_text not in current_notes_content:
        how_to_pattern = r"(##\s*(?:How to Use this File|Usage Guidelines)[\s\S]*?)(---)"
        if re.search(how_to_pattern, current_notes_content):
            new_how_to = (
                r"\g<1>4. **CRITICAL INVARIANT:** NEVER create task-specific headings "
                r"(e.g., `## [Task XX.Y] Description` or `### [Task XX.Y]`) in `NOTES.md`. "
                r"Task completion details live in `git log` and `.agent/ARCHIVE.md`. "
                r"Architectural decisions live in `docs/adr/decisions.md`. In `NOTES.md`, "
                r"maintain and update ONLY the live tables/lists of active contracts, interfaces, and topology.\n\n\g<2>"
            )
            updated = re.sub(how_to_pattern, new_how_to, current_notes_content)
            if not dry_run:
                notes_file.write_text(updated, encoding="utf-8")
            actions.append("Injected Critical Invariant heading ban into NOTES.md")

    return actions


def inject_multi_agent_contracts(repo: Path, dry_run: bool) -> List[str]:
    """Point 3: Inject or upgrade Multi-Agent Subagent Topology & Micro-Contracts in NOTES.md."""
    actions: List[str] = []
    notes_file = repo / ".agent" / "NOTES.md"
    if not notes_file.is_file() or notes_file.is_symlink():
        return actions

    content = notes_file.read_text(encoding="utf-8", errors="ignore")

    has_current_multi_agent = (
        "Lead / Orchestrator" in content
        and "Fast-Link" in content
        and "Quota Floor Circuit Breaker" in content
        and "files_read" in content
        and "default-tier" in content
        and "Hermetic Agent Sandbox" in content
        and "hydra-llm-router" in content
        and "hydra_shared_net" in content
        and not re.search(
            r"free-fast|free-deep|hydra-ai-gateway|hydra\.homelab\.yegear\.dev|gemini-3\.8-flash-medium",
            content,
        )
        and ("hydra_ai_net" not in content or "hydra_router_internal" in content)
    )
    if has_current_multi_agent:
        return actions

    multi_agent_regex = re.compile(
        r"^#{2,3}\s+(?:\d+\.\s*)?Multi-Agent Collaboration Contracts\b[\s\S]*?(?=\n---|\n## |\n### (?!\s*(?:Multi-Agent|Worktree|Project Lifecycle|Multi-Account|Hermetic|LLM Gateway))|\Z)",
        re.MULTILINE,
    )
    if multi_agent_regex.search(content):
        updated = multi_agent_regex.sub(CANONICAL_MULTI_AGENT_CONTRACT.rstrip() + "\n", content, count=1)
        if not dry_run:
            notes_file.write_text(updated, encoding="utf-8")
        actions.append("Upgraded Multi-Agent Collaboration Contracts to 2-Tier / hydra-llm-router in NOTES.md")
    else:
        if "## Gotchas & Pitfalls" in content:
            updated = content.replace(
                "## Gotchas & Pitfalls",
                CANONICAL_MULTI_AGENT_CONTRACT + "\n---\n\n## Gotchas & Pitfalls",
                1,
            )
            if not dry_run:
                notes_file.write_text(updated, encoding="utf-8")
            actions.append("Injected Multi-Agent Collaboration Contracts into NOTES.md")
        elif "## Pitfalls & Gotchas" in content:
            updated = content.replace(
                "## Pitfalls & Gotchas",
                CANONICAL_MULTI_AGENT_CONTRACT + "\n---\n\n## Pitfalls & Gotchas",
                1,
            )
            if not dry_run:
                notes_file.write_text(updated, encoding="utf-8")
            actions.append("Injected Multi-Agent Collaboration Contracts into NOTES.md")
        else:
            updated = content.rstrip() + "\n\n---\n\n" + CANONICAL_MULTI_AGENT_CONTRACT
            if not dry_run:
                notes_file.write_text(updated, encoding="utf-8")
            actions.append("Appended Multi-Agent Collaboration Contracts to NOTES.md")

    return actions


def upgrade_agents_md(repo: Path, dry_run: bool) -> List[str]:
    """Point 4: Refactor AGENTS.md to High-Density [P0]-[P3] Precedence Matrix & Fail-Stop."""
    actions: List[str] = []
    agents_file = repo / "AGENTS.md"
    if not agents_file.is_file():
        return actions

    content = agents_file.read_text(encoding="utf-8", errors="ignore")

    has_p0 = "[P0]" in content
    has_fail_stop = "Fail-Stop" in content or "fail-stop" in content.lower()
    has_contrast = "// BAD:" in content or "# BAD:" in content or "BAD:" in content

    if has_p0 and has_fail_stop and has_contrast:
        return actions

    updated = content
    if not has_p0:
        precedence_table = """## Priority Ranking & Precedence

Resolve directive conflicts using the strict canonical precedence hierarchy:

| Priority | Tier | Rules & Invariants |
| :---: | :--- | :--- |
| **`[P0]`** | **Security & Blast Radius** | Zero credential exposure, prohibit destructive git operations (`--force`, `reset --hard`) and destructive docker data actions. |
| **`[P1]`** | **Payload Invariants & Automated Contracts** | Single ADR diary (`docs/adr/decisions.md`), `NOTES.md` heading ban, schema contracts, strict typing (zero unchecked `any`). |
| **`[P2]`** | **Architecture & Test Harness** | Domain logic separation, canonical test command pass, consultative dependencies. |
| **`[P3]`** | **Style & Documentation** | Conventional Commits, Technical English for agent directives and commits. |

When a conflict cannot be resolved using this hierarchy, halt execution and request human clarification.
"""
        old_prec_regex = r"##\s*(?:[0-9.]*\s*)?(?:⚖️\s*)?(?:Rule\s+)?(?:Priority|Precedence)\s+(?:Ranking|Hierarchy|Precedence)[\s\S]*?(?=##\s+|\Z)"
        if re.search(old_prec_regex, updated):
            updated = re.sub(old_prec_regex, precedence_table + "\n", updated)
            actions.append("Replaced old precedence section with High-Density [P0]-[P3] table")
        else:
            scope_regex = r"(##\s*(?:[0-9.]*\s*)?Scope\s+&?\s*Blast\s+Radius[\s\S]*?)(?=##\s+|\Z)"
            if re.search(scope_regex, updated):
                updated = re.sub(scope_regex, r"\1\n" + precedence_table + "\n", updated)
                actions.append("Injected High-Density [P0]-[P3] precedence table after Scope & Blast Radius")
            else:
                first_h2 = updated.find("## ")
                if first_h2 != -1:
                    updated = updated[:first_h2] + precedence_table + "\n" + updated[first_h2:]
                else:
                    updated += "\n\n" + precedence_table
                actions.append("Appended High-Density [P0]-[P3] precedence table")

    if not has_fail_stop:
        if "## Contrast Pairs" in updated:
            updated = updated.replace("## Contrast Pairs", FAIL_STOP_SECTION + "\n\n## Contrast Pairs")
        else:
            updated = updated.rstrip() + "\n\n" + FAIL_STOP_SECTION
        actions.append("Injected Fail-Stop Protocol & Escalation Hierarchy")

    if not has_contrast and "Contrast Pairs" not in updated:
        updated = updated.rstrip() + "\n\n" + CONTRAST_PAIRS_SECTION
        actions.append("Injected Contrast Pairs into AGENTS.md")

    if not dry_run and updated != content:
        agents_file.write_text(updated, encoding="utf-8")

    return actions


CANONICAL_ROOT = Path(__file__).resolve().parents[2]
INTERFACE_SKILL = Path('.agent/skills/interface-testing/SKILL.md')
INTERFACE_HEADING = '7. Adaptive Interface Verification & UI Protocol'
INTERFACE_CONTEXT = ('- Interface & UI verification: Read `.agent/skills/interface-testing/SKILL.md` '
                     '(loaded on-demand exclusively for UI, preview, or frontend component tasks).')
INTERFACE_DOD = ('- [ ] Interface & UI verification (if UI affected): passes adaptive protocol '
                 '(interactive preview/device MCPs within T3 Code; non-blocking headless component/build validation outside T3 Code).')


class InterfaceConflict(ValueError):
    """A contract needs human reconciliation before any migration writes."""


def masked_markdown(text: str) -> str:
    """Hide examples/comments while preserving offsets into the original document."""
    def blank(value: str) -> str:
        return re.sub(r'[^\r\n]', ' ', value)

    masked = re.sub(r'<!--(?:.*?-->|.*\Z)', lambda match: blank(match[0]), text, flags=re.DOTALL)
    lines = []
    fence = ''
    for line in masked.splitlines(keepends=True):
        match = re.match(r'^ {0,3}(`{3,}|~{3,})(.*)$', line)
        if not fence and match:
            fence = match[1]
            lines.append(blank(line))
        elif fence:
            if match and match[1][0] == fence[0] and len(match[1]) >= len(fence) and not match[2].strip():
                fence = ''
            lines.append(blank(line))
        else:
            lines.append(line)
    if fence or re.search(r'<!--(?![\s\S]*-->)', text):
        raise InterfaceConflict('close unterminated Markdown fences/comments before adding active contracts')
    return ''.join(lines)


def interface_section(text: str, pattern: str) -> tuple[int, int] | None:
    headings = list(re.finditer(r'^(#{1,6})[ \t]+([^\r\n]+)', masked_markdown(text), re.MULTILINE))
    matches = [heading for heading in headings if re.search(pattern, heading[2])]
    if len(matches) > 1:
        raise InterfaceConflict(f'consolidate duplicate sections matching {pattern!r}')
    if not matches:
        return None
    start = matches[0]
    end = next((heading.start() for heading in headings
                if heading.start() > start.start() and len(heading[1]) <= len(start[1])), len(text))
    return start.end(), end


def append_interface_section(text: str, title: str, addition: str, span: tuple[int, int] | None) -> str:
    """Insert without rewriting any existing bytes, including CRLF line endings."""
    newline = '\r\n' if '\r\n' in text else '\n'
    addition = addition.replace('\r\n', '\n').replace('\n', newline)
    if span is None:
        return text + newline * 2 + '## ' + title + newline * 2 + addition + newline
    position = span[1]
    return text[:position] + newline * 2 + addition + newline * 2 + text[position:]


def safe_interface_read(repo: Path, relative: Path) -> bytes | None:
    """Reject symlink ancestors and nonregular contracts, even for missing targets."""
    target = repo / relative
    for path in [repo, *(repo / Path(*relative.parts[:i]) for i in range(1, len(relative.parts) + 1))]:
        if path.is_symlink():
            raise InterfaceConflict(f'{path}: replace the symlink with a local contract path')
        if path.exists() and (not path.is_dir() if path != target else not path.is_file()):
            raise InterfaceConflict(f'{path}: expected a {"file" if path == target else "directory"}')
    try:
        payload = target.read_bytes()
        payload.decode('utf-8')
        return payload
    except FileNotFoundError:
        return None
    except (OSError, UnicodeError) as error:
        raise InterfaceConflict(f'{target}: restore a readable UTF-8 contract ({type(error).__name__})') from error


def interface_invariants(text: str) -> str:
    canonical = safe_interface_read(CANONICAL_ROOT, Path('.agent/INVARIANTS.md'))
    if canonical is None:
        raise InterfaceConflict('restore canonical .agent/INVARIANTS.md in the hub')
    canonical_text = canonical.decode('utf-8')
    canonical_span = interface_section(canonical_text, '^' + re.escape(INTERFACE_HEADING) + '$')
    if canonical_span is None:
        raise InterfaceConflict('restore canonical Invariant 7 section in the hub')
    canonical_body = canonical_text[slice(*canonical_span)].strip()
    label_pattern = r'^- \*\*Invariant (7\.\d+) [^\r\n]*'

    def blocks(body: str) -> dict[str, str]:
        labels = list(re.finditer(label_pattern, masked_markdown(body), re.MULTILINE))
        result = {}
        for index, label in enumerate(labels):
            end = labels[index + 1].start() if index + 1 < len(labels) else len(body)
            block = body[label.start():end]
            block = re.split(r'^(?:---[ \t]*$|- (?!\*\*Invariant ))', block, maxsplit=1, flags=re.MULTILINE)[0]
            if label[1] in result:
                raise InterfaceConflict(f'Invariant {label[1]}: consolidate duplicate blocks')
            result[label[1]] = '\n'.join(line.rstrip() for line in block.strip().splitlines())
        return result

    expected = blocks(canonical_body)
    if any(not expected.get(f'7.{number}') for number in range(1, 5)):
        raise InterfaceConflict('restore complete canonical Invariants 7.1–7.4 in the hub')
    span = interface_section(text, '^' + re.escape(INTERFACE_HEADING) + '$')
    active = masked_markdown(text)
    # Section 7 is reserved by the shared contract; never repurpose a custom section.
    for heading in re.finditer(r'^#{1,6}[ \t]+7[.)][ \t]+([^\r\n]+)', active, re.MULTILINE):
        if heading[1] != 'Adaptive Interface Verification & UI Protocol':
            raise InterfaceConflict('section 7 is project-specific; reconcile its numbering with shared Invariants 7.1–7.4')
    outside = active if span is None else active[:span[0]] + ' ' * (span[1] - span[0]) + active[span[1]:]
    if re.search(r'\bInvariant 7\.\d+', outside):
        raise InterfaceConflict('move existing Invariant 7 contracts into the single canonical section for review')
    body = '' if span is None else active[slice(*span)]
    actual = blocks(body)
    # Detect malformed labels too, rather than appending a second competing rule.
    if len(re.findall(r'\bInvariant 7\.\d+', body)) != len(actual):
        raise InterfaceConflict('reconcile malformed or repeated Invariant 7 labels')
    for key, block in actual.items():
        if key in expected and block != expected[key]:
            raise InterfaceConflict(f'Invariant {key}: reconcile custom text with the canonical block; no overwrite performed')
    missing = [block for key, block in expected.items() if key not in actual]
    if missing:
        return append_interface_section(text, INTERFACE_HEADING, '\n'.join(missing), span)
    return text


def interface_agents(text: str) -> str:
    for title, pattern, directive, candidate, compliant in [
        ('Modular Context Triggers', r'Modular Context Triggers', INTERFACE_CONTEXT,
         lambda line: INTERFACE_SKILL.as_posix() in line or bool(re.search(r'interface.*(?:context|skill)', line, re.I)),
         lambda line: bool(re.match(r'^ {0,3}- ', line)) and line.strip() == INTERFACE_CONTEXT),
        ('Falsifiable Definition of Done (DoD)', r'Falsifiable Definition of Done', INTERFACE_DOD,
         lambda line: bool(re.search(r'(?:interface|\bUI\b|preview).*(?:verif|test)|(?:verif|test).*(?:interface|\bUI\b|preview)', line, re.I)),
         lambda line: line == INTERFACE_DOD),
    ]:
        span = interface_section(text, pattern)
        if span is None and title.startswith('Falsifiable') and interface_section(text, r'Definition of Done|\bDoD\b') is not None:
            raise InterfaceConflict('reconcile custom DoD heading with Falsifiable Definition of Done before migration')
        active = masked_markdown(text)
        body = '' if span is None else active[slice(*span)]
        outside = active if span is None else active[:span[0]] + active[span[1]:]
        if title.startswith('Falsifiable') and any(
            re.match(r'^- \[.\] ', line) and candidate(line)
            for line in outside.splitlines()
        ):
            raise InterfaceConflict('move custom interface verification checkboxes into the shared DoD for review')
        candidates = [line for line in body.splitlines() if candidate(line)]
        if any(not compliant(line) for line in candidates) or len(candidates) > 1:
            raise InterfaceConflict(f'{title}: reconcile custom or duplicate interface directives before migration')
        if not candidates:
            if title == 'Modular Context Triggers' and INTERFACE_SKILL.as_posix() in active:
                raise InterfaceConflict('move the existing interface skill directive into Modular Context Triggers for review')
            text = append_interface_section(text, title, directive, span)
    return text


def plan_interface_contracts(repo: Path) -> dict[Path, bytes]:
    """Preflight the complete opt-in change before touching any project files."""
    paths = [INTERFACE_SKILL, Path('.agent/INVARIANTS.md'), Path('AGENTS.md')]
    existing = {path: safe_interface_read(repo, path) for path in paths}
    skill = safe_interface_read(CANONICAL_ROOT, INTERFACE_SKILL)
    if not skill or not skill.strip():
        raise InterfaceConflict('restore the nonempty canonical interface-testing skill in the hub')
    if existing[INTERFACE_SKILL] is not None and existing[INTERFACE_SKILL] != skill:
        raise InterfaceConflict(f'{INTERFACE_SKILL}: compare custom skill with the hub canonical version and reconcile manually')
    if existing[Path('AGENTS.md')] is None:
        raise InterfaceConflict('AGENTS.md: create project governance before opting into interface contracts')
    desired = {
        INTERFACE_SKILL: skill,
        Path('.agent/INVARIANTS.md'): interface_invariants((existing[Path('.agent/INVARIANTS.md')] or b'').decode()).encode(),
        Path('AGENTS.md'): interface_agents(existing[Path('AGENTS.md')].decode()).encode(),
    }
    return {path: content for path, content in desired.items() if content != existing[path]}


def ensure_gitignore_two_tier(repo: Path, dry_run: bool) -> List[str]:
    """Ensure .gitignore ignores worktrees and dev-harness ephemeral directories."""
    if not (repo / ".agent").is_dir() and not (repo / "AGENTS.md").is_file():
        return []
    gi_file = repo / ".gitignore"
    if gi_file.is_symlink():
        return ["Skipped .gitignore two-tier rules: symlinked .gitignore"]
    if gi_file.exists() and not gi_file.is_file():
        return ["Skipped .gitignore two-tier rules: .gitignore is not a regular file"]

    existing = gi_file.read_text(encoding="utf-8", errors="ignore") if gi_file.is_file() else ""
    newline = "\r\n" if "\r\n" in existing else "\n"
    existing_lines = {line.strip() for line in existing.splitlines()}

    missing: List[str] = []
    for rule in GITIGNORE_INVARIANTS:
        if rule == ".worktrees/" and (".worktrees/" in existing_lines or ".worktrees" in existing_lines):
            continue
        if rule not in existing_lines:
            missing.append(rule)

    if not missing:
        return []

    block_lines = (
        (["# Agent & dev-harness ephemeral state"] if "# Agent & dev-harness ephemeral state" not in existing_lines else [])
        + missing
    )
    if existing:
        sep = "" if existing.endswith(("\n", "\r\n")) else newline
        updated = existing + sep + newline + newline.join(block_lines) + newline
    else:
        updated = newline.join(block_lines) + newline

    if not dry_run:
        write_adr_diary(gi_file, updated.encode("utf-8"))
    return [f"Added {len(missing)} runtime/harness ignore rule(s) to .gitignore: {', '.join(missing)}"]


def ensure_hooks_readme(repo: Path, dry_run: bool) -> List[str]:
    """Provision canonical .agent/hooks/README.md when .agent/ exists and hooks dir is missing or empty."""
    agent_dir = repo / ".agent"
    if not agent_dir.is_dir() or agent_dir.is_symlink():
        return []

    hooks_dir = agent_dir / "hooks"
    if hooks_dir.is_symlink():
        return ["Skipped .agent/hooks/README.md: symlinked .agent/hooks directory"]
    if hooks_dir.exists() and not hooks_dir.is_dir():
        return ["Skipped .agent/hooks/README.md: .agent/hooks is not a directory"]
    if hooks_dir.exists() and any(hooks_dir.iterdir()):
        return []

    canonical = safe_interface_read(CANONICAL_ROOT, Path(".agent/hooks/README.md"))
    if not canonical:
        return []

    if not dry_run:
        hooks_dir.mkdir(parents=True, exist_ok=True)
        write_adr_diary(hooks_dir / "README.md", canonical)
    return ["Provisioned canonical .agent/hooks/README.md"]


def upgrade_agents_two_tier(repo: Path, dry_run: bool) -> List[str]:
    """Upgrade AGENTS.md with 2-Tier rigor and Hermetic Skills while removing obsolete batch/spec rules."""
    agents_file = repo / "AGENTS.md"
    if not agents_file.is_file() or agents_file.is_symlink():
        return []

    content = agents_file.read_text(encoding="utf-8", errors="ignore")
    try:
        masked = masked_markdown(content)
    except InterfaceConflict:
        return ["Skipped AGENTS.md 2-Tier upgrade: unterminated Markdown fence or comment"]

    newline = "\r\n" if "\r\n" in content else "\n"
    raw_lines = content.splitlines(keepends=True)
    masked_lines = masked.splitlines(keepends=True)

    new_lines: List[str] = []
    for raw_line, masked_line in zip(raw_lines, masked_lines):
        # Only strip/rewrite active markdown lines (preserve examples inside code fences/comments).
        if not masked_line.strip() and raw_line.strip():
            new_lines.append(raw_line)
            continue

        stripped = raw_line.rstrip("\r\n")
        ending = raw_line[len(stripped):] or newline

        if re.match(r"^[ \t]*-[ \t]+(?:\*\*)?Ephemeral [Ff]eature [Ss]pec", stripped):
            continue
        if re.match(r"^[ \t]*-[ \t]+\*\*(?:Pre-Approved \(`APPROVED`\)|Sequential Sub-Task Batching \(`\[BATCH: Bx\]`\)):", stripped):
            continue
        std_match = re.match(r"^([ \t]*)-[ \t]+\*\*Standard \(`READY FOR PLANNING`\):", stripped)
        if std_match:
            indent = std_match.group(1)
            new_lines.append(
                f"{indent}- **Plan approval:** Present an action plan detailing affected files, "
                f"await explicit user approval, then execute the active task's `- [ ]` checklist in `.agent/TASK.md`.{ending}"
            )
            continue

        line_updated = stripped.replace("to `READY FOR PLANNING`", "to the active task")
        line_updated = line_updated.replace("active in `RUNNING` status", "active in `.agent/TASK.md`")
        new_lines.append(line_updated + (raw_line[len(stripped):]))

    updated = "".join(new_lines)
    active_after = masked_markdown(updated)

    has_two_tier = all(
        marker in active_after
        for marker in ("Tier 1", "Tier 2", "dev-harness", ".harness/queue/", "files_read", "files_edit")
    )
    has_hermetic = "Hermetic Skills & Context Contract" in active_after

    if not has_two_tier:
        section = TWO_TIER_AGENTS_SECTION.strip().replace("\n", newline)
        sep = "" if updated.endswith((newline * 2, "\n\n", "\r\n\r\n")) else (newline if updated.endswith(("\n", "\r\n")) else newline * 2)
        updated = updated + sep + section + newline
    elif not has_hermetic:
        hermetic_section = (
            "## Hermetic Skills & Context Contract" + newline * 2
            + "- **Hermetic Skills & Context Contract:** Procedural guidelines and skills must be self-contained "
            + "within `.agent/skills/` or injected directly into the task dispatch prompt by the orchestrator; "
            + "never wander the host filesystem for missing skills." + newline
        )
        sep = "" if updated.endswith((newline * 2, "\n\n", "\r\n\r\n")) else (newline if updated.endswith(("\n", "\r\n")) else newline * 2)
        updated = updated + sep + hermetic_section

    actions: List[str] = []
    if updated != content:
        if not dry_run:
            write_adr_diary(agents_file, updated.encode("utf-8"))
        actions.append("Upgraded AGENTS.md to 2-Tier Progressive Rigor & Hermetic Skills")

    remaining_legacy = re.search(
        r"Ephemeral Feature Specs|\*\*Sequential Sub-Task Batching|\*\*Pre-Approved",
        masked_markdown(updated),
    )
    if remaining_legacy:
        actions.append(f"Warning: AGENTS.md retains custom legacy directive ({remaining_legacy.group(0)}); review manually")
    return actions


def sanitize_task_md_two_tier(repo: Path, dry_run: bool) -> List[str]:
    """Strip legacy batch/status/spec-anchor ceremony from active sections of .agent/TASK.md."""
    task_file = repo / ".agent" / "TASK.md"
    if not task_file.is_file() or task_file.is_symlink():
        return []

    content = task_file.read_text(encoding="utf-8", errors="ignore")
    try:
        masked = masked_markdown(content)
    except InterfaceConflict:
        return ["Skipped .agent/TASK.md cleanup: unterminated Markdown fence or comment"]

    newline = "\r\n" if "\r\n" in content else "\n"
    raw_lines = content.splitlines(keepends=True)
    masked_lines = masked.splitlines(keepends=True)

    new_lines: List[str] = []
    in_completed_log = False
    for raw_line, masked_line in zip(raw_lines, masked_lines):
        if re.match(r"^##\s+Completed Tasks Log\b", masked_line):
            in_completed_log = True
        elif re.match(r"^##\s+", masked_line):
            in_completed_log = False

        if in_completed_log or (not masked_line.strip() and raw_line.strip()):
            new_lines.append(raw_line)
            continue

        stripped = raw_line.rstrip("\r\n")
        ending = raw_line[len(stripped):]

        if re.match(r"^[ \t]*-\s*\*\*(?:Status|Systems Involved|Action Type|Spec Anchor):\*\*", stripped):
            continue
        if re.match(r"^[ \t]*-\s*(?:\*\*)?Read:(?:\*\*)?[ \t]+.*\.agent/scratch/specs/", stripped):
            continue

        line_updated = re.sub(r"[ \t]*\[(?:BATCH|PARALLEL): [A-Za-z0-9x-]+\]", "", stripped)
        line_updated = re.sub(r"[ \t]*\[(?:APPROVED|READY FOR PLANNING)\]", "", line_updated)
        line_updated = line_updated.replace("to `READY FOR PLANNING`", "to the active task")
        line_updated = re.sub(r"\bREADY FOR PLANNING\b", "Active Task", line_updated)
        line_updated = line_updated.rstrip()
        new_lines.append(line_updated + ending)

    updated = "".join(new_lines)
    if "Task | Title | Commit(s) | Date" not in updated and "## Backlog" not in updated:
        sep = "" if updated.endswith((newline * 2, "\n\n", "\r\n\r\n")) else (newline if updated.endswith(("\n", "\r\n")) else newline * 2)
        updated = (
            updated + sep
            + "## Completed Tasks Log" + newline * 2
            + "| Task | Title | Commit(s) | Date |" + newline
            + "|---|---|---|---|" + newline
        )

    if updated == content:
        return []
    if not dry_run:
        write_adr_diary(task_file, updated.encode("utf-8"))
    return ["Sanitized .agent/TASK.md to lean Tier 1 format (removed batch/status ceremony)"]


def align_env_example_hydra(repo: Path, dry_run: bool) -> List[str]:
    """Align .env.example and residual NOTES.md references with hydra-llm-router contracts."""
    actions: List[str] = []
    replacements = [
        (re.compile(r"hydra-ai-gateway"), "hydra-llm-router"),
        (re.compile(r"hydra\.homelab\.yegear\.dev"), "hydra-router.homelab.yegear.dev"),
        (re.compile(r"\bfree-fast\b"), "fast"),
        (re.compile(r"\bfree-deep\b"), "deep"),
    ]

    for rel_path, label in (
        (Path(".env.example"), "Aligned .env.example with hydra-llm-router contracts"),
        (Path(".agent/NOTES.md"), "Aligned residual gateway references in .agent/NOTES.md with hydra-llm-router"),
    ):
        target = repo / rel_path
        if not target.is_file() or target.is_symlink():
            continue
        content = target.read_text(encoding="utf-8", errors="ignore")
        updated = content
        for pattern, replacement in replacements:
            updated = pattern.sub(replacement, updated)
        if updated != content:
            if not dry_run:
                write_adr_diary(target, updated.encode("utf-8"))
            actions.append(label)

    return actions


def apply_standards_to_repo(
    repo: Path,
    dry_run: bool = False,
    include_interface_contracts: bool = False,
    include_two_tier: bool = False,
) -> List[str]:
    """Apply legacy governance, with optional preflighted interface and 2-Tier adoption."""
    actions: List[str] = []
    if include_interface_contracts:
        try:
            changes = plan_interface_contracts(repo)
        except (InterfaceConflict, OSError) as error:
            return [f"Blocked interface migration: {error}. Repository unchanged; reconcile and retry."]
        for path, content in changes.items():
            if not dry_run:
                write_adr_diary(repo / path, content)
            actions.append(f"Install interface contract: {path}")
    actions.extend(consolidate_adrs(repo, dry_run))
    actions.extend(sanitize_notes_md(repo, dry_run))
    actions.extend(inject_multi_agent_contracts(repo, dry_run))
    actions.extend(upgrade_agents_md(repo, dry_run))
    if include_two_tier:
        actions.extend(ensure_gitignore_two_tier(repo, dry_run))
        actions.extend(ensure_hooks_readme(repo, dry_run))
        actions.extend(upgrade_agents_two_tier(repo, dry_run))
        actions.extend(sanitize_task_md_two_tier(repo, dry_run))
        actions.extend(align_env_example_hydra(repo, dry_run))
    return actions


class TestApplyGovernanceStandards(unittest.TestCase):
    """Hermetic unit and integration test suite for governance standards propagator."""

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)

    def tearDown(self):
        self.temp_dir.cleanup()

    def create_mock_legacy_repo(self, name: str = "test-repo") -> Path:
        repo = self.root / name
        repo.mkdir(parents=True, exist_ok=True)
        (repo / ".git").mkdir()

        # Legacy AGENTS.md
        (repo / "AGENTS.md").write_text("# Agent Guidelines\nSome general intro\n", encoding="utf-8")

        # Legacy .agent directory
        agent_dir = repo / ".agent"
        agent_dir.mkdir()
        (agent_dir / "TASK.md").write_text("# TASK.md\n## Active Task", encoding="utf-8")
        (agent_dir / "NOTES.md").write_text(
            "# NOTES.md\n\n## Usage Guidelines\n\n---\n\n## [Task 01.1] Setup Environment\nDetails of task\n\n## [Task 01.2] Config\nMore details\n\n## Pitfalls & Gotchas\nSome gotchas",
            encoding="utf-8"
        )
        (agent_dir / "ARCHIVE.md").write_text("# ARCHIVE.md\nHistorical archive\n", encoding="utf-8")

        # Legacy .agent/adr
        legacy_adr = agent_dir / "adr"
        legacy_adr.mkdir()
        (legacy_adr / "001-init.md").write_text("# 1. Initial Architecture\nDecision details", encoding="utf-8")

        return repo

    def test_full_migration(self):
        repo = self.create_mock_legacy_repo("migrated-repo")
        actions = apply_standards_to_repo(repo, dry_run=False)
        self.assertGreater(len(actions), 0)

        # 1. ADR consolidated and directory removed
        self.assertFalse((repo / ".agent" / "adr").exists())
        decisions_file = repo / "docs" / "adr" / "decisions.md"
        self.assertTrue(decisions_file.exists())
        self.assertIn("1. Initial Architecture", decisions_file.read_text(encoding="utf-8"))

        # 2. NOTES.md sanitized and tasks moved to ARCHIVE.md
        notes_text = (repo / ".agent" / "NOTES.md").read_text(encoding="utf-8")
        self.assertNotIn("## [Task 01.1]", notes_text)
        self.assertIn("NEVER create task-specific headings", notes_text)
        archive_text = (repo / ".agent" / "ARCHIVE.md").read_text(encoding="utf-8")
        self.assertIn("## [Task 01.1]", archive_text)

        # 3. Multi-agent contracts injected
        self.assertIn("Lead / Orchestrator", notes_text)

        # 4. AGENTS.md upgraded
        agents_text = (repo / "AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("[P0]", agents_text)
        self.assertIn("Fail-Stop Protocol", agents_text)
        self.assertIn("Contrast Pairs", agents_text)

    def test_dry_run_preserves_files(self):
        repo = self.create_mock_legacy_repo("dry-run-repo")
        actions = apply_standards_to_repo(repo, dry_run=True)
        self.assertGreater(len(actions), 0)

        # Assert no filesystem mutations occurred
        self.assertTrue((repo / ".agent" / "adr").exists())
        self.assertFalse((repo / "docs" / "adr" / "decisions.md").exists())
        notes_text = (repo / ".agent" / "NOTES.md").read_text(encoding="utf-8")
        self.assertIn("## [Task 01.1]", notes_text)
        agents_text = (repo / "AGENTS.md").read_text(encoding="utf-8")
        self.assertNotIn("[P0]", agents_text)

    def test_idempotent_migration(self):
        repo = self.create_mock_legacy_repo("idempotent-repo")
        apply_standards_to_repo(repo, dry_run=False)

        # Re-apply standards
        second_actions = apply_standards_to_repo(repo, dry_run=False)
        self.assertEqual(len(second_actions), 0)


    def snapshot(self, repo: Path) -> dict[str, bytes | str | None]:
        snapshot: dict[str, bytes | str | None] = {}
        for path in sorted(repo.rglob("*")):
            key = str(path.relative_to(repo))
            if path.is_symlink():
                snapshot[key] = os.readlink(path)
            elif path.is_dir():
                snapshot[key] = None
            else:
                snapshot[key] = path.read_bytes()
        return snapshot

    def adr_fixture(self) -> tuple[Path, Path, Path]:
        repo = self.create_mock_legacy_repo("adr-fixture")
        return repo, repo / ".agent" / "adr", repo / "docs" / "adr" / "decisions.md"

    def test_unsupported_assets_block_entire_tree(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        assets = legacy / "assets"
        assets.mkdir()
        (assets / "diagram.png").write_bytes(b"\x89PNG\x00\xff")
        (legacy / "notes.txt").write_bytes(b"keep notes")
        before = self.snapshot(repo)
        actions = consolidate_adrs(repo, dry_run=False)
        self.assertEqual(self.snapshot(repo), before)
        self.assertFalse(diary.exists())
        self.assertTrue(any("diagram.png" in action for action in actions))
        self.assertTrue(any("notes.txt" in action for action in actions))
        self.assertTrue(all("Blocked ADR consolidation" in action for action in actions))

    def test_asset_only_tree_is_not_mistaken_for_empty(self) -> None:
        repo, legacy, _ = self.adr_fixture()
        (legacy / "001-init.md").unlink()
        (legacy / "only.bin").write_bytes(b"\x00asset")
        before = self.snapshot(repo)
        consolidate_adrs(repo, dry_run=False)
        self.assertEqual(self.snapshot(repo), before)

    def test_nested_decisions_and_templates_preserve_exact_bytes(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        nested = legacy / "nested"
        nested.mkdir()
        payloads = [b"# Template\n\nKeep template rationale.\n", b"# Nested\r\n\r\nDecision with CRLF.\r\n"]
        (legacy / "000-template.md").write_bytes(payloads[0])
        (nested / "002-decision.MD").write_bytes(payloads[1])
        consolidate_adrs(repo, dry_run=False)
        self.assertFalse(legacy.exists())
        persisted = preserved_adr_documents(diary.read_bytes())
        self.assertTrue(all(payload in persisted for payload in payloads))

    def test_same_title_different_bodies_and_existing_diary_are_preserved(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        diary.parent.mkdir(parents=True)
        existing = b"# 1. Initial Architecture\r\nPrevious decision body.\r\n"
        diary.write_bytes(existing)
        other = b"# 1. Initial Architecture\nA different decision body.\n"
        (legacy / "002-other.md").write_bytes(other)
        original = (legacy / "001-init.md").read_bytes()
        consolidate_adrs(repo, dry_run=False)
        content = diary.read_bytes()
        self.assertTrue(content.startswith(existing))
        self.assertIn(original, preserved_adr_documents(content))
        self.assertIn(other, preserved_adr_documents(content))

    def test_identical_documents_are_consolidated_once(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        original = (legacy / "001-init.md").read_bytes()
        (legacy / "duplicate.md").write_bytes(original)
        consolidate_adrs(repo, dry_run=False)
        self.assertEqual(diary.read_bytes().count(original), 1)
        self.assertFalse(legacy.exists())

    def test_existing_complete_document_is_not_duplicated(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        original = (legacy / "001-init.md").read_bytes() + b"\n"
        (legacy / "001-init.md").write_bytes(original)
        diary.parent.mkdir(parents=True)
        existing = b"# Diary\n\n---\n\n" + original
        diary.write_bytes(existing)
        consolidate_adrs(repo, dry_run=False)
        self.assertEqual(diary.read_bytes(), existing)

    def test_invalid_utf8_blocks_without_silent_byte_loss(self) -> None:
        repo, legacy, _ = self.adr_fixture()
        (legacy / "bad.md").write_bytes(b"# ADR\n\xff")
        before = self.snapshot(repo)
        actions = consolidate_adrs(repo, dry_run=False)
        self.assertEqual(self.snapshot(repo), before)
        self.assertTrue(any("bad.md: UnicodeDecodeError" in action for action in actions))

    def test_invalid_diary_blocks_without_overwriting_history(self) -> None:
        repo, _, diary = self.adr_fixture()
        diary.parent.mkdir(parents=True)
        diary.write_bytes(b"existing \xff history")
        before = self.snapshot(repo)
        actions = consolidate_adrs(repo, dry_run=False)
        self.assertEqual(self.snapshot(repo), before)
        self.assertTrue(any("decisions.md: UnicodeDecodeError" in action for action in actions))

    def test_symlinked_source_and_destination_are_not_followed(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        outside = self.root / "outside.md"
        outside.write_bytes(b"external content")
        (legacy / "linked.md").symlink_to(outside)
        before = self.snapshot(repo)
        self.assertTrue(consolidate_adrs(repo, dry_run=False))
        self.assertEqual(self.snapshot(repo), before)
        (legacy / "linked.md").unlink()
        diary.parent.mkdir(parents=True)
        diary.symlink_to(outside)
        before = self.snapshot(repo)
        self.assertTrue(consolidate_adrs(repo, dry_run=False))
        self.assertEqual(self.snapshot(repo), before)
        self.assertEqual(outside.read_bytes(), b"external content")

    def test_symlinked_legacy_directory_is_retained(self) -> None:
        repo = self.root / "symlinked-repo"
        (repo / ".agent").mkdir(parents=True)
        outside = self.root / "outside-adrs"
        outside.mkdir()
        (outside / "decision.md").write_bytes(b"# Outside\nKeep me.")
        (repo / ".agent" / "adr").symlink_to(outside, target_is_directory=True)
        before = self.snapshot(repo)
        self.assertTrue(consolidate_adrs(repo, dry_run=False))
        self.assertEqual(self.snapshot(repo), before)
        self.assertEqual((outside / "decision.md").read_bytes(), b"# Outside\nKeep me.")

    def test_dry_run_preserves_all_paths_and_bytes(self) -> None:
        repo, legacy, _ = self.adr_fixture()
        (legacy / "nested").mkdir()
        (legacy / "nested" / "nested.md").write_bytes(b"# Nested\n\nKeep trailing spaces.  \n")
        before = self.snapshot(repo)
        apply_standards_to_repo(repo, dry_run=True)
        self.assertEqual(self.snapshot(repo), before)

    def test_second_application_preserves_all_paths_and_bytes(self) -> None:
        repo, _, _ = self.adr_fixture()
        apply_standards_to_repo(repo, dry_run=False)
        before = self.snapshot(repo)
        self.assertEqual(apply_standards_to_repo(repo, dry_run=False), [])
        self.assertEqual(self.snapshot(repo), before)

    def test_empty_tree_cleanup_creates_no_diary(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        (legacy / "001-init.md").unlink()
        (legacy / "empty").mkdir()
        consolidate_adrs(repo, dry_run=False)
        self.assertFalse(legacy.exists())
        self.assertFalse(diary.exists())

    def test_empty_markdown_document_is_preserved(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        (legacy / "empty.md").write_bytes(b"")
        consolidate_adrs(repo, dry_run=False)
        self.assertFalse(legacy.exists())
        self.assertIn(b"", preserved_adr_documents(diary.read_bytes()))

    def test_replace_failure_keeps_existing_diary_and_sources(self) -> None:
        repo, _, diary = self.adr_fixture()
        diary.parent.mkdir(parents=True)
        diary.write_bytes(b"# Existing diary\n")
        before = self.snapshot(repo)
        with patch("os.replace", side_effect=OSError("injected replace failure")):
            with self.assertRaisesRegex(OSError, "injected replace failure"):
                consolidate_adrs(repo, dry_run=False)
        self.assertEqual(self.snapshot(repo), before)
        consolidate_adrs(repo, dry_run=False)
        self.assertTrue(diary.read_bytes().startswith(b"# Existing diary\n"))

    def test_failed_readback_keeps_sources_and_retry_does_not_duplicate(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        original = (legacy / "001-init.md").read_bytes()
        read_bytes = Path.read_bytes

        def read_with_mismatch(path: Path) -> bytes:
            if path == diary:
                return b"injected readback mismatch"
            return read_bytes(path)

        with patch.object(Path, "read_bytes", read_with_mismatch):
            with self.assertRaisesRegex(OSError, "diary verification failed"):
                consolidate_adrs(repo, dry_run=False)
        self.assertEqual((legacy / "001-init.md").read_bytes(), original)
        consolidate_adrs(repo, dry_run=False)
        self.assertEqual(diary.read_bytes().count(original), 1)

    def test_partial_cleanup_failure_is_recoverable(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        remaining = legacy / "002-other.md"
        payload = b"# Another decision\nPreserve after interrupted cleanup."
        remaining.write_bytes(payload)
        unlink = Path.unlink

        def fail_one_unlink(path: Path, missing_ok: bool = False) -> None:
            if path == remaining:
                raise OSError("injected cleanup failure")
            unlink(path, missing_ok=missing_ok)

        with patch.object(Path, "unlink", fail_one_unlink):
            with self.assertRaisesRegex(OSError, "injected cleanup failure"):
                consolidate_adrs(repo, dry_run=False)
        before = diary.read_bytes()
        self.assertEqual(remaining.read_bytes(), payload)
        consolidate_adrs(repo, dry_run=False)
        self.assertEqual(diary.read_bytes(), before)
        self.assertFalse(legacy.exists())

    def test_changed_source_blocks_cleanup(self) -> None:
        repo, legacy, diary = self.adr_fixture()
        original = legacy / "001-init.md"
        inspect = inspect_legacy_adrs
        calls = 0

        def inspect_with_change(path: Path) -> tuple[dict[Path, bytes], list[Path], list[str]]:
            nonlocal calls
            calls += 1
            if calls == 2:
                original.write_bytes(b"# Changed after inventory\nNew content.")
            return inspect(path)

        with patch(__name__ + ".inspect_legacy_adrs", side_effect=inspect_with_change):
            with self.assertRaisesRegex(OSError, "tree changed"):
                consolidate_adrs(repo, dry_run=False)
        self.assertEqual(original.read_bytes(), b"# Changed after inventory\nNew content.")
        self.assertIn(b"Decision details", diary.read_bytes())

    def test_two_tier_opt_in_migration_and_idempotency(self) -> None:
        repo = self.create_mock_legacy_repo("two-tier-repo")
        (repo / ".gitignore").write_text(".env\n.worktrees/\n", encoding="utf-8")
        (repo / ".env.example").write_text(
            "LLM_BASE_URL=https://hydra.homelab.yegear.dev/v1\n"
            "LLM_MODEL_FAST=free-fast\n"
            "LLM_MODEL_DEEP=free-deep\n",
            encoding="utf-8",
        )
        (repo / "AGENTS.md").write_text(
            "# Rules\n\n[P0] Keep data.\n\n## Fail-Stop\n\nStop.\n\n## Contrast Pairs\n\nBAD: break\n\n"
            "## Modular Context Triggers\n"
            "  - Ephemeral feature specifications (Batch Context Anchor): Read `.agent/scratch/specs/<XX-YY>.md`.\n\n"
            "## Mandatory Execution Protocol\n"
            "  - **Standard (`READY FOR PLANNING`):** Wait.\n"
            "  - **Pre-Approved (`APPROVED`):** Go.\n"
            "  - **Sequential Sub-Task Batching (`[BATCH: Bx]`):** Batch.\n",
            encoding="utf-8",
        )
        (repo / ".agent" / "TASK.md").write_text(
            "# TASK.md\n\n## Active Task\n\n### [02.1] Build feature [BATCH: B1]\n"
            "- **Status:** READY FOR PLANNING\n"
            "- **Action Type:** code\n"
            "- **Read:** `.agent/scratch/specs/02-01.md`\n"
            "- [ ] Implement endpoint [PARALLEL: W1]\n\n"
            "## Completed Tasks Log\n\n"
            "| Task | Title | Commit(s) | Date |\n|---|---|---|---|\n"
            "| `[01.1]` | Legacy [BATCH: B0] | `abc123` | 2026-11-01 |\n",
            encoding="utf-8",
        )
        (repo / ".agent" / "NOTES.md").write_text(
            "# NOTES.md\n\n## Active Contracts\n\n"
            "### 2. Multi-Agent Collaboration Contracts\n\n"
            "| Role | Channel | Responsibilities | Boundary |\n|---|---|---|---|\n"
            "| `Worker` | Worktree | `gemini-3.8-flash-medium` | `Read:` / `Paths:` |\n\n"
            "#### LLM Gateway\nUse `hydra-ai-gateway`, `free-fast`, and `hydra_ai_net`.\n\n"
            "---\n\n## Pitfalls & Gotchas\n\n- Keep probes on `free-deep` >= 60 tokens.\n",
            encoding="utf-8",
        )

        # Dry-run leaves everything untouched
        before = self.snapshot(repo)
        dry_actions = apply_standards_to_repo(repo, dry_run=True, include_two_tier=True)
        self.assertGreater(len(dry_actions), 0)
        self.assertEqual(self.snapshot(repo), before)

        # Apply 2-Tier standards
        actions = apply_standards_to_repo(repo, dry_run=False, include_two_tier=True)
        self.assertGreater(len(actions), 0)

        agents_text = (repo / "AGENTS.md").read_text(encoding="utf-8")
        for marker in ("Tier 1", "Tier 2", "dev-harness", ".harness/queue/", "files_read", "files_edit", "Hermetic Skills & Context Contract"):
            self.assertIn(marker, agents_text)
        self.assertNotIn("Ephemeral feature specifications", agents_text)
        self.assertNotIn("**Pre-Approved", agents_text)
        self.assertNotIn("**Sequential Sub-Task Batching", agents_text)

        task_text = (repo / ".agent" / "TASK.md").read_text(encoding="utf-8")
        self.assertNotIn("[BATCH: B1]", task_text)
        self.assertNotIn("[PARALLEL: W1]", task_text)
        self.assertNotIn("- **Status:**", task_text)
        self.assertNotIn(".agent/scratch/specs/02-01.md", task_text)
        self.assertIn("[BATCH: B0]", task_text)  # Historical Completed Tasks Log preserved

        gi_text = (repo / ".gitignore").read_text(encoding="utf-8")
        self.assertIn(".harness/queue/done/", gi_text)
        self.assertIn(".harness/queue/escalated/", gi_text)
        self.assertIn(".harness/worktrees/", gi_text)
        self.assertTrue((repo / ".agent" / "hooks" / "README.md").is_file())

        env_text = (repo / ".env.example").read_text(encoding="utf-8")
        self.assertIn("hydra-router.homelab.yegear.dev", env_text)
        self.assertIn("LLM_MODEL_FAST=fast", env_text)
        self.assertIn("LLM_MODEL_DEEP=deep", env_text)

        notes_text = (repo / ".agent" / "NOTES.md").read_text(encoding="utf-8")
        self.assertIn("hydra-llm-router", notes_text)
        self.assertIn("hydra_shared_net", notes_text)
        self.assertNotIn("free-deep", notes_text)
        self.assertNotIn("gemini-3.8-flash-medium", notes_text)

        # Idempotent on second run
        second_actions = apply_standards_to_repo(repo, dry_run=False, include_two_tier=True)
        self.assertEqual(second_actions, [])


def run_self_tests() -> int:
    """Execute hermetic unit and verification test suite."""
    print("==> Executing apply-governance-standards.py hermetic self-test suite...")
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromTestCase(TestApplyGovernanceStandards)
    suite.addTests(loader.discover(str(Path(__file__).parent / "tests"), pattern="test_interface_migration.py"))
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return 0 if result.wasSuccessful() else 1


def main():
    parser = argparse.ArgumentParser(
        description="Aplica padrões de governança ADD selecionados aos projetos."
    )
    parser.add_argument("path", nargs="?", default="", help="Diretório raiz (padrão: ~/github ou diretório atual)")
    parser.add_argument("--dir", "-d", dest="dir_opt", default="", help="Alternativa para caminho raiz")
    parser.add_argument("--dry-run", action="store_true", help="Apenas simula as alterações sem gravar nos arquivos")
    parser.add_argument("--repo", help="Aplica exclusivamente no repositório especificado")
    parser.add_argument("--exclude", nargs="*", default=list(DEFAULT_EXCLUDED_NAMES),
                        help="Nomes de repositórios/diretórios a excluir do cálculo")
    parser.add_argument("--no-exclude", action="store_true", help="Desabilita filtros padrão de exclusão")
    parser.add_argument("--include-interface-contracts", action="store_true",
                        help="Opt in to canonical interface contracts; conflicts leave the repository unchanged (exit 1)")
    parser.add_argument("--include-two-tier", action="store_true",
                        help="Opt in to 2-Tier Progressive Rigor, .harness/ gitignore, hooks README, lean TASK.md, and hydra-llm-router alignment")
    parser.add_argument("--all-standards", action="store_true",
                        help="Enable both --include-interface-contracts and --include-two-tier")
    parser.add_argument("--self-test", action="store_true", help="Executa suíte de testes unitários herméticos")

    args = parser.parse_args()

    if args.self_test:
        sys.exit(run_self_tests())

    target_dir_str = args.dir_opt or args.path or str(Path.home() / "github")
    root_path = Path(target_dir_str).expanduser().resolve()

    if not root_path.exists():
        print(f"Erro: Caminho '{root_path}' não existe.", file=sys.stderr)
        sys.exit(2)

    print(f"Iniciando aplicação dos padrões de governança em: {root_path}")
    if args.dry_run:
        print("[MODO SIMULAÇÃO / DRY-RUN ATIVADO — NENHUM ARQUIVO SERÁ ALTERADO]")

    candidate_repos = find_git_repos(root_path, max_depth=4)
    is_direct_single_target = len(candidate_repos) == 1 and candidate_repos[0] == root_path

    exclusion_list = [] if args.no_exclude else [e.strip() for e in args.exclude if e and e.strip()]

    repos: List[Path] = []
    for repo_dir in candidate_repos:
        if not is_direct_single_target and exclusion_list:
            if any(exc in repo_dir.name for exc in exclusion_list):
                continue
        if args.repo and repo_dir.name != args.repo:
            continue
        repos.append(repo_dir)

    print(f"Total de repositórios candidatos: {len(repos)}\n")

    include_interface = args.include_interface_contracts or args.all_standards
    include_two_tier = args.include_two_tier or args.all_standards

    total_changes = 0
    blocked = False
    for repo in repos:
        repo_name = f"{repo.parent.name}/{repo.name}" if repo.parent.name else repo.name
        actions = apply_standards_to_repo(repo, args.dry_run, include_interface, include_two_tier)
        blocked |= any(action.startswith("Blocked interface migration:") for action in actions)
        if actions:
            total_changes += len(actions)
            print(f"📦 {repo_name}:")
            for act in actions:
                print(f"  ✓ {act}")
            print()

    print("=" * 60)
    mode_str = "Simulação concluída" if args.dry_run else "Aplicação concluída com sucesso"
    if blocked:
        mode_str = "Interface migration blocked in one or more repositories"
    print(f"{mode_str}! Total de ações executadas/planejadas: {total_changes}")
    if blocked:
        sys.exit(1)


if __name__ == "__main__":
    main()
