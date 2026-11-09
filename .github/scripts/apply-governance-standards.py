#!/usr/bin/env python3
"""
apply-governance-standards.py

Automated propagator and migration runner for ADD (Agent-Driven Development) governance standards:
  1. Single ADR Diary (docs/adr/decisions.md) & Purge legacy .agent/adr/
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

import argparse
import os
import re
import shutil
import sys
import tempfile
import unittest
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


def consolidate_adrs(repo: Path, dry_run: bool) -> List[str]:
    """Point 1: Consolidate .agent/adr/*.md into docs/adr/decisions.md and remove .agent/adr/"""
    actions: List[str] = []
    agent_adr_dir = repo / ".agent" / "adr"
    if not agent_adr_dir.is_dir():
        return actions

    docs_adr_dir = repo / "docs" / "adr"
    decisions_file = docs_adr_dir / "decisions.md"

    adr_files = sorted([f for f in agent_adr_dir.iterdir() if f.is_file() and f.suffix == ".md"])
    if not adr_files:
        if not dry_run:
            shutil.rmtree(agent_adr_dir)
        actions.append("Removed empty .agent/adr/ directory")
        return actions

    existing_content = ""
    if decisions_file.is_file():
        existing_content = decisions_file.read_text(encoding="utf-8", errors="ignore")

    new_adrs_content: List[str] = []
    for adr_path in adr_files:
        if adr_path.name == "000-template.md" and len(adr_files) > 1:
            continue
        adr_text = adr_path.read_text(encoding="utf-8", errors="ignore").strip()
        # Check if already present in decisions.md
        title_match = re.search(r"^#+\s*(.+)$", adr_text, re.MULTILINE)
        if title_match:
            title = title_match.group(1).strip()
            if title in existing_content:
                continue
        new_adrs_content.append(f"\n---\n\n{adr_text}\n")

    if not decisions_file.is_file():
        base_header = (
            f"# Architecture Decision Records — {repo.name}\n\n"
            f"Consolidated chronological log of architectural decisions for {repo.name}.\n"
        )
        full_content = base_header + "".join(new_adrs_content)
        if not dry_run:
            docs_adr_dir.mkdir(parents=True, exist_ok=True)
            decisions_file.write_text(full_content, encoding="utf-8")
        actions.append(f"Created docs/adr/decisions.md with {len(new_adrs_content)} consolidated ADRs")
    elif new_adrs_content:
        full_content = existing_content.rstrip() + "\n" + "".join(new_adrs_content)
        if not dry_run:
            decisions_file.write_text(full_content, encoding="utf-8")
        actions.append(f"Appended {len(new_adrs_content)} missing ADRs to docs/adr/decisions.md")
    else:
        actions.append("All ADRs already present in docs/adr/decisions.md")

    if not dry_run:
        shutil.rmtree(agent_adr_dir)
    actions.append("Purged legacy .agent/adr/ directory")

    return actions


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
