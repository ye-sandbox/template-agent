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
    --self-test           Run hermetic unit and verification test suite
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

CANONICAL_MULTI_AGENT_CONTRACT = """### 2. Multi-Agent Collaboration Contracts (Optional)

> Canonical 3-tier subagent topology, delegation micro-contracts, and worktree isolation. If operating single-agent, leave as default.

| Role | Interface / Channel | Responsibilities | Boundary & Invariants |
|---|---|---|---|
| **`Lead / Orchestrator`** | `.agent/TASK.md` / Interactive Prompt | Decomposes initiatives into wave-compatible tasks, manages task lifecycle, routes to model/quota tiers, interacts with human. | Sole manager of `TASK.md` and commit log. Does not run parallel worker tasks directly. |
| **`Worker / Implementer`** | Worktree / Target Workspace | Executes atomic code/doc changes strictly adhering to delegated micro-contract (`Read:`, `Paths:`, `Verify:`). | Restricted exclusively to `Paths:`. Adheres to DoD in `AGENTS.md`. |
| **`Reviewer / Sentinel`** | Diffs / Test Harness (`Verify:`) | Read-only inspection of diffs against task DoD, regression tests, and security blast radius. | Read-only; reports structured Pass/Fail diagnostic payload. |

#### Worktree Isolation & Dependency Bootstrap Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Workspace Provisioning** | `git worktree add -b task-<id> <path> HEAD` | Default ephemeral path (`${TMPDIR:-/tmp}/worktrees/task-<id>`) or `.worktrees/task-<id>` (`.worktrees/` in `.gitignore`). |
| **Dependency Bootstrap** | Fast-Link vs. Isolated-Install | Fast-Link (symlink `node_modules/` or `.venv/`) when `Paths:` has no manifest changes (<50ms, zero-copy). Isolated-Install when manifests change. |
| **Environment Injection** | Copy `.env` / `.env.example` to worktree | Ensures test harness execution without leaking uncommitted tokens or mutating root config. |
| **Teardown & GC** | `git worktree remove --force` + `branch -D` + `prune` | Immediate cleanup post-integration; trap declared in runners to prevent dangling worktree locks. |

#### Multi-Account Quota Routing & Failover Contract

| Element | Protocol / Mechanism | Invariant / Boundary |
|---|---|---|
| **Profile Routing Priority** | `select-profile.sh --exclude-current` | Autonomous workers route to secondary accounts with highest quota; active IDE profile reserved for Lead Orchestrator. |
| **Quota Floor Circuit Breaker** | `remaining_fraction <= 0.05` | Immediate disqualification of profiles with <=5% quota; halts execution if all candidate profiles are below floor. |
| **Model Tier Selection** | `gemini-3.8-flash-medium` | Low token footprint default; escalation to `gemini-4-argon-medium` permitted only for complex architecture or max 1 retry after verification failure. |
| **Cooldown Tracking** | `<profile>/.multigravity/quota-history.jsonl` | 429 rate limit backoff and cooldown persistence to prevent immediate re-dispatch. |
| **Worktree Recovery** | Worktree verify on timeout | Runs `Verify:` inside worktree on timeout; if code 0 and matches `Paths:`, recovers diff cleanly. |
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
[01.6] Status: READY FOR PLANNING -> Directly edited 10 files without plan approval

// GOOD: Standard Plan-First progression
[01.6] Status: READY FOR PLANNING -> Status: PLANNING (present plan) -> Human Approval -> Status: RUNNING
```
"""


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
    if not notes_file.is_file():
        return actions

    content = notes_file.read_text(encoding="utf-8", errors="ignore")

    # If already has full v1.3.0 contracts, skip
    if "Lead / Orchestrator" in content and "Fast-Link" in content and "Quota Floor Circuit Breaker" in content:
        return actions

    # If has older Multi-Agent section, replace it
    multi_agent_regex = r"### 2\. Multi-Agent Collaboration Contracts[\s\S]*?(?=---\n|## Gotchas|\Z)"
    if re.search(multi_agent_regex, content):
        updated = re.sub(multi_agent_regex, CANONICAL_MULTI_AGENT_CONTRACT + "\n", content)
        if not dry_run:
            notes_file.write_text(updated, encoding="utf-8")
        actions.append("Upgraded Multi-Agent Collaboration Contracts to v1.3.0 in NOTES.md")
    else:
        if "## Gotchas & Pitfalls" in content:
            updated = content.replace("## Gotchas & Pitfalls", CANONICAL_MULTI_AGENT_CONTRACT + "\n---\n\n## Gotchas & Pitfalls")
            if not dry_run:
                notes_file.write_text(updated, encoding="utf-8")
            actions.append("Injected Multi-Agent Collaboration Contracts (v1.3.0) into NOTES.md")
        elif "## Pitfalls & Gotchas" in content:
            updated = content.replace("## Pitfalls & Gotchas", CANONICAL_MULTI_AGENT_CONTRACT + "\n---\n\n## Pitfalls & Gotchas")
            if not dry_run:
                notes_file.write_text(updated, encoding="utf-8")
            actions.append("Injected Multi-Agent Collaboration Contracts (v1.3.0) into NOTES.md")
        else:
            updated = content.rstrip() + "\n\n---\n\n" + CANONICAL_MULTI_AGENT_CONTRACT
            if not dry_run:
                notes_file.write_text(updated, encoding="utf-8")
            actions.append("Appended Multi-Agent Collaboration Contracts (v1.3.0) to NOTES.md")

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


def apply_standards_to_repo(repo: Path, dry_run: bool = False) -> List[str]:
    """Apply all 4 governance transformations to a single repository."""
    actions: List[str] = []
    actions.extend(consolidate_adrs(repo, dry_run))
    actions.extend(sanitize_notes_md(repo, dry_run))
    actions.extend(inject_multi_agent_contracts(repo, dry_run))
    actions.extend(upgrade_agents_md(repo, dry_run))
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


def run_self_tests() -> int:
    """Execute hermetic unit and verification test suite."""
    print("==> Executing apply-governance-standards.py hermetic self-test suite...")
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromTestCase(TestApplyGovernanceStandards)
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

    total_changes = 0
    for repo in repos:
        repo_name = f"{repo.parent.name}/{repo.name}" if repo.parent.name else repo.name
        actions = apply_standards_to_repo(repo, args.dry_run)
        if actions:
            total_changes += len(actions)
            print(f"📦 {repo_name}:")
            for act in actions:
                print(f"  ✓ {act}")
            print()

    print("=" * 60)
    mode_str = "Simulação concluída" if args.dry_run else "Aplicação concluída com sucesso"
    print(f"{mode_str}! Total de ações executadas/planejadas: {total_changes}")


if __name__ == "__main__":
    main()
