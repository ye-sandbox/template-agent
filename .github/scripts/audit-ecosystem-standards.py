#!/usr/bin/env python3
"""
audit-ecosystem-standards.py

Heuristic scanner and compliance auditor for Agent-Driven Development (ADD) templates.
Recursively inspects directories for Git repositories and assesses adherence to
template-agent standards, including adaptive interface verification.
The legacy 100-point rubric plus 20 interface points is normalized to 0-100.

Usage:
    python3 audit-ecosystem-standards.py [ROOT_DIR] [OPTIONS]
    python3 audit-ecosystem-standards.py --self-test

Options:
    --dir, -d PATH        Root directory to scan (default: ~/github or current dir)
    --max-depth, -m N     Maximum search depth for git repositories (default: 4)
    --format, -f FORMAT   Output format: table (default), markdown, json
    --output, -o FILE     Write results to file instead of stdout
    --fail-under N        Exit with code 1 if average score < N (e.g. 70)
    --exclude [REPO ...]  Repository directory names to exclude
    --no-exclude          Do not apply default exclusion filters
    --self-test           Run hermetic unit and verification test suite
    --verbose, -v         Display detailed checks for each repository
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path
from typing import Any, Dict, List, Set

IGNORED_DIR_NAMES = {
    "node_modules", ".venv", "venv", ".git", ".worktrees", "tmp",
    "cache", ".cache", "dist", "build", "target", "vendor",
    ".system_generated", ".gemini", ".claude", "__pycache__"
}

DEFAULT_EXCLUDED_NAMES = {
    "template-agent", "agent-skills", ".github", "yegear1", "org-ye-sandbox"
}


CANONICAL_ROOT = Path(__file__).resolve().parent.parent.parent
INTERFACE_SKILL = Path(".agent/skills/interface-testing/SKILL.md")
INTERFACE_WEIGHTS = {
    "interface_skill_installed": 2,
    "interface_skill_canonical": 4,
    **{f"interface_invariant_7_{number}": 2 for number in range(1, 5)},
    "interface_context_on_demand": 3,
    "interface_dod_dual_runtime": 3,
}


def active_markdown(text: str) -> str:
    """Discard fenced examples and HTML comments before checking directives."""
    text = re.sub(r"<!--(?:.*?-->|.*\Z)", "", text, flags=re.DOTALL)
    lines: list[str] = []
    fence = ""
    for line in text.splitlines():
        match = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if not fence and match:
            fence = match[1]
        elif fence:
            if match and match[1][0] == fence[0] and len(match[1]) >= len(fence) and not match[2].strip():
                fence = ""
        else:
            lines.append(line)
    return "\n".join(lines)


def contract_section(text: str, title: str) -> str:
    """Select exactly one active section, stopping at a peer/ancestor heading."""
    headings = list(re.finditer(r"^(#{1,6})[ \t]+([^\n]+)$", text, re.MULTILINE))
    matches = [heading for heading in headings if re.search(title, heading[2])]
    if len(matches) != 1:
        return ""
    start = matches[0]
    end = next((heading.start() for heading in headings
                if heading.start() > start.start() and len(heading[1]) <= len(start[1])), len(text))
    return text[start.end():end]


def invariant_blocks(text: str) -> dict[str, str]:
    section = contract_section(active_markdown(text), r"^7\. Adaptive Interface Verification & UI Protocol$")
    labels = list(re.finditer(r"^- \*\*Invariant (7\.\d+) [^\n]*$", section, re.MULTILINE))
    blocks: dict[str, str] = {}
    for index, label in enumerate(labels):
        end = labels[index + 1].start() if index + 1 < len(labels) else len(section)
        block = section[label.start():end]
        block = re.split(r"^(?:---[ \t]*$|- (?!\*\*Invariant ))", block, maxsplit=1, flags=re.MULTILINE)[0]
        normalized = "\n".join(line.rstrip() for line in block.strip().splitlines())
        has_body = re.search(r"^ {2,}- \S", normalized, re.MULTILINE) is not None
        blocks[label[1]] = "" if label[1] in blocks or not has_body else normalized
    return blocks


def read_interface_contract(path: Path, role: str, violations: list[str]) -> bytes | None:
    try:
        if path.is_symlink():
            raise OSError("symlinked contract")
        content = path.read_bytes()
        content.decode("utf-8")
        return content
    except (OSError, UnicodeError) as error:
        violations.append(f"Interface contract: cannot read {role} at {path} ({type(error).__name__}).")
        return None


def audit_interface_contracts(repo: Path) -> tuple[dict[str, bool], list[str]]:
    violations: list[str] = []
    canonical_skill = read_interface_contract(CANONICAL_ROOT / INTERFACE_SKILL, "canonical skill", violations)
    canonical_rules = read_interface_contract(CANONICAL_ROOT / ".agent/INVARIANTS.md", "canonical invariants", violations)
    skill = read_interface_contract(repo / INTERFACE_SKILL, "installed skill", violations)
    rules = read_interface_contract(repo / ".agent/INVARIANTS.md", "project invariants", violations)
    agents = read_interface_contract(repo / "AGENTS.md", "project AGENTS.md", violations)
    expected = invariant_blocks(canonical_rules.decode()) if canonical_rules is not None else {}
    actual = invariant_blocks(rules.decode()) if rules is not None else {}
    directives = active_markdown(agents.decode()) if agents is not None else ""
    context = contract_section(directives, r"Modular Context Triggers")
    dod = contract_section(directives, r"Falsifiable Definition of Done")
    checks = {
        "interface_skill_installed": skill is not None and bool(skill.strip()),
        "interface_skill_canonical": bool(canonical_skill and canonical_skill.strip()) and skill == canonical_skill,
    }
    for number in range(1, 5):
        key = f"7.{number}"
        checks[f"interface_invariant_7_{number}"] = bool(expected.get(key)) and actual.get(key) == expected[key]
        if not expected.get(key):
            violations.append(f"Interface contract: canonical Invariant {key} is missing or duplicated.")
    checks["interface_context_on_demand"] = any(
        re.match(r"^ {0,3}- ", line) is not None
        and INTERFACE_SKILL.as_posix() in line
        and re.search(r"on[- ]demand", line, re.IGNORECASE) is not None
        and "interface" in line.lower()
        for line in context.splitlines()
    )
    checks["interface_dod_dual_runtime"] = any(
        re.match(r"^- \[ \] ", line) is not None
        and all(token in line.lower() for token in ["interface", "ui", "verif", "t3 code", "headless"])
        for line in dod.splitlines()
    )
    repairs = {
        "interface_skill_installed": f"install a readable UTF-8 {INTERFACE_SKILL}",
        "interface_skill_canonical": "restore the canonical interface-testing skill bytes",
        **{f"interface_invariant_7_{n}": f"restore the complete canonical Invariant 7.{n} block once" for n in range(1, 5)},
        "interface_context_on_demand": "add the on-demand skill reference to Modular Context Triggers",
        "interface_dod_dual_runtime": "add an active UI verification DoD checkbox with both T3 Code and headless paths",
    }
    violations.extend(f"Interface contract: {key}: {repairs[key]}." for key, passed in checks.items() if not passed)
    return checks, violations


def find_git_repos(root_dir: Path, max_depth: int = 4) -> List[Path]:
    """Recursively discover unique git repository roots up to max_depth."""
    repos: List[Path] = []
    seen_paths: Set[Path] = set()

    root_dir = root_dir.resolve()
    if not root_dir.exists():
        return repos

    # If the root_dir itself is a git repo, return it directly
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


def audit_repository(repo_path: Path) -> Dict[str, Any]:
    """Evaluate a single git repository against template-agent standards."""
    name = repo_path.name
    parent_name = repo_path.parent.name
    display_name = f"{parent_name}/{name}" if parent_name else name

    checks: Dict[str, bool] = {}
    violations: List[str] = []

    # 1. AGENTS.md
    agents_file = repo_path / "AGENTS.md"
    checks["has_agents_md"] = agents_file.is_file()

    agents_content = ""
    if checks["has_agents_md"]:
        try:
            agents_content = agents_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            pass

    has_p0 = "[P0]" in agents_content
    has_precedence = any(kw in agents_content for kw in [
        "Priority Ranking", "Precedence Hierarchy", "Rule Precedence", "Priority Hierarchy"
    ])
    has_blast_radius = "Blast Radius" in agents_content or "Scope & Blast" in agents_content
    checks["agents_high_density"] = has_p0 and (has_precedence or has_blast_radius)
    checks["agents_fail_stop"] = "Fail-Stop" in agents_content or "fail-stop" in agents_content.lower()
    checks["agents_contrast_pairs"] = (
        "// BAD:" in agents_content or "# BAD:" in agents_content or "BAD:" in agents_content
    )

    # 2. .agent/ Directory and Core Governance
    agent_dir = repo_path / ".agent"
    checks["has_agent_dir"] = agent_dir.is_dir()

    task_file = agent_dir / "TASK.md"
    checks["has_task_md"] = task_file.is_file()

    notes_file = agent_dir / "NOTES.md"
    checks["has_notes_md"] = notes_file.is_file()

    archive_file = agent_dir / "ARCHIVE.md"
    checks["has_archive_md"] = archive_file.is_file()

    invariants_file = agent_dir / "INVARIANTS.md"
    checks["has_invariants_md"] = invariants_file.is_file()

    # Rule: ban on task headings inside NOTES.md
    notes_bad_heading = False
    notes_subagents = False
    if checks["has_notes_md"]:
        try:
            notes_lines = notes_file.read_text(encoding="utf-8", errors="ignore").splitlines()
            for line in notes_lines:
                # Matches real headings like "## [Task 01.1]" or "### 2026-11-02 [Task 08.1]" or "## [01.1] Setup"
                if re.match(r"^##+\s*(\[?\d{4}-\d{2}-\d{2}\]?\s*)?\[?(?:Task\s+)?\d{2}\.\d+", line, re.IGNORECASE):
                    notes_bad_heading = True
                    violations.append(f"NOTES.md contains task-specific heading: '{line.strip()}'")
                    break
            notes_text = "\n".join(notes_lines)
            if "Lead / Orchestrator" in notes_text or "Fast-Link" in notes_text or "Micro-Contract" in notes_text:
                notes_subagents = True
        except Exception:
            pass

    checks["notes_no_task_headings"] = not notes_bad_heading if checks["has_notes_md"] else True
    checks["notes_has_subagent_contract"] = notes_subagents

    # 3. ADR Architecture (Single ADR in docs/adr/decisions.md)
    single_adr_file = repo_path / "docs" / "adr" / "decisions.md"
    checks["has_single_adr"] = single_adr_file.is_file()

    legacy_adr_dir = agent_dir / "adr"
    checks["no_legacy_adr_dir"] = not legacy_adr_dir.is_dir()
    if legacy_adr_dir.is_dir():
        violations.append("Legacy '.agent/adr/' directory found (violates Single ADR Diary standard)")

    # 4. v1.3.0 Standards: Worktree Isolation & Lifecycle Hooks
    gitignore_file = repo_path / ".gitignore"
    has_worktree_ignore = False
    if gitignore_file.is_file():
        try:
            gi_content = gitignore_file.read_text(encoding="utf-8", errors="ignore")
            if re.search(r"^\.worktrees/?$", gi_content, re.MULTILINE):
                has_worktree_ignore = True
        except Exception:
            pass
    checks["worktrees_in_gitignore"] = has_worktree_ignore

    hooks_dir = agent_dir / "hooks"
    checks["has_agent_hooks"] = hooks_dir.is_dir() and any(hooks_dir.iterdir()) if hooks_dir.is_dir() else False

    # 5. v1.3.0 Standards: LLM Gateway Contract
    env_example_file = repo_path / ".env.example"
    has_llm_gateway = False
    if env_example_file.is_file():
        try:
            env_content = env_example_file.read_text(encoding="utf-8", errors="ignore")
            if "LLM_BASE_URL" in env_content and ("LLM_MODEL_FAST" in env_content or "LLM_MODEL_DEEP" in env_content):
                has_llm_gateway = True
        except Exception:
            pass
    checks["llm_gateway_in_env_example"] = has_llm_gateway

    # 6. Documentation & Hygiene
    readme_pt = repo_path / "README.pt-br.md"
    checks["has_bilingual_readme"] = readme_pt.is_file()

    changelog_file = repo_path / "CHANGELOG.md"
    checks["has_changelog"] = changelog_file.is_file()

    interface_checks, interface_violations = audit_interface_contracts(repo_path)
    checks.update(interface_checks)
    violations.extend(interface_violations)

    # Keep the legacy 100 points; add 20 interface points and normalize over 120.
    # A legacy-perfect project missing every interface check now scores 83%.

    weights = {
        "has_agents_md": 15,
        "agents_high_density": 10,
        "agents_fail_stop": 5,
        "has_agent_dir": 10,
        "has_task_md": 10,
        "has_notes_md": 5,
        "has_invariants_md": 4,
        "notes_no_task_headings": 10,
        "has_single_adr": 10,
        "no_legacy_adr_dir": 5,
        "worktrees_in_gitignore": 5,
        "llm_gateway_in_env_example": 4,
        "notes_has_subagent_contract": 3,
        "has_agent_hooks": 2,
        "has_bilingual_readme": 1,
        "has_changelog": 1,
    }

    weights.update(INTERFACE_WEIGHTS)
    score = 0
    max_score = sum(weights.values())
    for k, w in weights.items():
        if checks.get(k, False):
            score += w

    percentage = round((score / max_score) * 100) if max_score > 0 else 0

    # Classify Tier
    if not checks["has_agent_dir"] or not checks["has_agents_md"]:
        tier = "Tier 4 (Sem Padrão / Legado)"
    elif not checks["no_legacy_adr_dir"] or not checks["notes_no_task_headings"]:
        tier = "Tier 3 (Com Débito Técnico)"
    elif percentage >= 80:
        tier = "Tier 1 (Vanguarda / v1.3.0 Ready)"
    elif percentage >= 55:
        tier = "Tier 2 (Conforme v1.1 / v1.2)"
    else:
        tier = "Tier 3 (Com Débito Técnico)"

    return {
        "name": display_name,
        "path": str(repo_path),
        "score": percentage,
        "tier": tier,
        "checks": checks,
        "violations": violations,
    }


def format_table(results: List[Dict[str, Any]]) -> str:
    """Format audit results as a readable ANSI/ASCII terminal table."""
    header = (
        f"{'Repositório':<33} | {'Tier':<28} | {'Score':<5} | "
        f"{'AGENTS':<6} | {'HD/P0':<5} | {'ADR':<5} | {'NoLegADR':<8} | "
        f"{'CleanNts':<8} | {'WkTree':<6} | {'LLM':<4} | {'Hooks':<5}"
    )
    divider = "-" * len(header)
    lines = [divider, header, divider]

    for r in results:
        c = r["checks"]
        p_ag = "SIM" if c.get("has_agents_md") else "NÃO"
        p_hd = "SIM" if c.get("agents_high_density") else "não"
        p_adr = "SIM" if c.get("has_single_adr") else "não"
        p_no_leg = "ok" if c.get("no_legacy_adr_dir") else "DEBITO"
        p_cln_nts = "ok" if c.get("notes_no_task_headings") else "DEBITO"
        p_wkt = "SIM" if c.get("worktrees_in_gitignore") else "não"
        p_llm = "SIM" if c.get("llm_gateway_in_env_example") else "não"
        p_hks = "SIM" if c.get("has_agent_hooks") else "não"

        line = (
            f"{r['name']:<33} | {r['tier']:<28} | {r['score']:>4}% | "
            f"{p_ag:<6} | {p_hd:<5} | {p_adr:<5} | {p_no_leg:<8} | "
            f"{p_cln_nts:<8} | {p_wkt:<6} | {p_llm:<4} | {p_hks:<5}"
        )
        lines.append(line)

    lines.append(divider)
    for result in results:
        lines.extend(f"- {result['name']}: {message}" for message in result["violations"]
                     if message.startswith("Interface contract:"))
    return "\n".join(lines)


def format_markdown(results: List[Dict[str, Any]]) -> str:
    """Format audit results as a GitHub-flavored Markdown table."""
    md = [
        "| Repositório | Nível / Tier | Score | AGENTS.md | HD (P0-P3) | Single ADR | Sem ADR Legado | NOTES.md Limpo | .worktrees | LLM Gateway | Hooks |",
        "| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |"
    ]
    for r in results:
        c = r["checks"]
        p_ag = "✅" if c.get("has_agents_md") else "❌"
        p_hd = "✅" if c.get("agents_high_density") else "⚪"
        p_adr = "✅" if c.get("has_single_adr") else "⚪"
        p_no_leg = "✅" if c.get("no_legacy_adr_dir") else "⚠️ Débito"
        p_cln_nts = "✅" if c.get("notes_no_task_headings") else "⚠️ Débito"
        p_wkt = "✅" if c.get("worktrees_in_gitignore") else "⚪"
        p_llm = "✅" if c.get("llm_gateway_in_env_example") else "⚪"
        p_hks = "✅" if c.get("has_agent_hooks") else "⚪"

        md.append(
            f"| `{r['name']}` | {r['tier']} | **{r['score']}%** | {p_ag} | {p_hd} | {p_adr} | {p_no_leg} | {p_cln_nts} | {p_wkt} | {p_llm} | {p_hks} |"
        )
    diagnostics = [f"- `{result['name']}`: {message}" for result in results for message in result["violations"]
                   if message.startswith("Interface contract:")]
    if diagnostics:
        md.extend(["", *diagnostics])
    return "\n".join(md)


def print_summary(results: List[Dict[str, Any]]) -> str:
    total = len(results)
    if total == 0:
        return "Nenhum repositório Git encontrado."

    t1 = sum(1 for r in results if "Tier 1" in r["tier"])
    t2 = sum(1 for r in results if "Tier 2" in r["tier"])
    t3 = sum(1 for r in results if "Tier 3" in r["tier"])
    t4 = sum(1 for r in results if "Tier 4" in r["tier"])

    avg_score = round(sum(r["score"] for r in results) / total) if total > 0 else 0
    violations_count = sum(len(r["violations"]) for r in results)

    summary = [
        "\n=== Sumário da Auditoria Heurística ===",
        f"Total de Repositórios Analisados: {total}",
        f"Média Geral de Aderência: {avg_score}%",
        "----------------------------------------",
        f"  🌟 Tier 1 (Vanguarda / v1.3.0 Ready): {t1:>2} ({t1/total*100:4.1f}%)" if total else "",
        f"  ✅ Tier 2 (Conforme Base v1.1/v1.2):  {t2:>2} ({t2/total*100:4.1f}%)" if total else "",
        f"  ⚠️  Tier 3 (Com Débito Técnico):      {t3:>2} ({t3/total*100:4.1f}%)" if total else "",
        f"  ❌ Tier 4 (Sem Padrão / Legado):       {t4:>2} ({t4/total*100:4.1f}%)" if total else "",
        "----------------------------------------",
        f"Total de Violações Invariantes Detectadas: {violations_count}",
    ]
    return "\n".join([line for line in summary if line])


class TestAuditEcosystemStandards(unittest.TestCase):
    """Hermetic unit and integration test suite for ecosystem standards auditor."""

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)

    def tearDown(self):
        self.temp_dir.cleanup()

    def create_mock_repo(self, name: str, is_compliant: bool = True) -> Path:
        repo_dir = self.root / name
        repo_dir.mkdir(parents=True, exist_ok=True)
        (repo_dir / ".git").mkdir()

        if is_compliant:
            # Fully compliant repo
            (repo_dir / "AGENTS.md").write_text(
                "# Agent Guidelines\n[P0] Security & Blast Radius\n## Priority Ranking & Precedence\n"
                "## Fail-Stop Protocol\n// BAD: git commit -m 'fix'\n// GOOD: git commit -m 'feat: add'",
                encoding="utf-8"
            )
            agent_dir = repo_dir / ".agent"
            agent_dir.mkdir()
            (agent_dir / "TASK.md").write_text("# TASK.md\n## Active Task", encoding="utf-8")
            (agent_dir / "NOTES.md").write_text(
                "# NOTES.md\nLead / Orchestrator\nFast-Link\nMicro-Contract",
                encoding="utf-8"
            )
            (agent_dir / "ARCHIVE.md").write_text("# ARCHIVE.md", encoding="utf-8")
            (agent_dir / "INVARIANTS.md").write_text("# INVARIANTS.md", encoding="utf-8")
            hooks_dir = agent_dir / "hooks"
            hooks_dir.mkdir()
            (hooks_dir / "post-worktree-create").write_text("#!/bin/bash\nexit 0", encoding="utf-8")

            docs_adr = repo_dir / "docs" / "adr"
            docs_adr.mkdir(parents=True)
            (docs_adr / "decisions.md").write_text("# Architecture Decisions", encoding="utf-8")

            (repo_dir / ".gitignore").write_text(".worktrees/\nnode_modules/\n", encoding="utf-8")
            (repo_dir / ".env.example").write_text(
                "LLM_BASE_URL=http://hydra-llm-router:3000/v1\nLLM_MODEL_FAST=fast\nLLM_MODEL_DEEP=deep\n",
                encoding="utf-8"
            )
            (repo_dir / "README.pt-br.md").write_text("# Documentação", encoding="utf-8")
            (repo_dir / "CHANGELOG.md").write_text("# Changelog", encoding="utf-8")
            (agent_dir / "INVARIANTS.md").write_bytes((CANONICAL_ROOT / ".agent/INVARIANTS.md").read_bytes())
            skill = repo_dir / INTERFACE_SKILL
            skill.parent.mkdir(parents=True)
            skill.write_bytes((CANONICAL_ROOT / INTERFACE_SKILL).read_bytes())
            agents = repo_dir / "AGENTS.md"
            agents.write_text(agents.read_text(encoding="utf-8") + (
                "\n## Modular Context Triggers\n"
                "- Interface & UI Verification: Read `.agent/skills/interface-testing/SKILL.md` on-demand for UI work.\n"
                "\n## Mandatory Execution Protocol\n"
                "### Step 3: Falsifiable Definition of Done (DoD)\n"
                "- [ ] Interface & UI Verification: T3 Code preview/device checks; headless component/build tests.\n"
            ), encoding="utf-8")
        else:
            # Legacy repo with violations
            (repo_dir / "AGENTS.md").write_text("# Agent Guidelines\nNo P0 here\n", encoding="utf-8")
            agent_dir = repo_dir / ".agent"
            agent_dir.mkdir()
            (agent_dir / "TASK.md").write_text("# TASK.md", encoding="utf-8")
            (agent_dir / "NOTES.md").write_text(
                "# NOTES.md\n## [Task 01.1] Setup environment\nSome legacy notes",
                encoding="utf-8"
            )
            # Legacy adr dir
            (agent_dir / "adr").mkdir()
            (agent_dir / "adr" / "001-init.md").write_text("# ADR 001", encoding="utf-8")

        return repo_dir

    def test_compliant_repo_score(self):
        repo = self.create_mock_repo("compliant-app", is_compliant=True)
        res = audit_repository(repo)
        self.assertEqual(res["score"], 100)
        self.assertIn("Tier 1", res["tier"])
        self.assertEqual(len(res["violations"]), 0)

    def test_legacy_repo_violations(self):
        repo = self.create_mock_repo("legacy-app", is_compliant=False)
        res = audit_repository(repo)
        self.assertIn("Tier 3", res["tier"])
        self.assertFalse(res["checks"]["no_legacy_adr_dir"])
        self.assertFalse(res["checks"]["notes_no_task_headings"])
        self.assertGreater(len(res["violations"]), 0)

    def test_bare_repo_tier4(self):
        bare_repo = self.root / "bare-repo"
        bare_repo.mkdir()
        (bare_repo / ".git").mkdir()
        res = audit_repository(bare_repo)
        self.assertIn("Tier 4", res["tier"])
        self.assertLess(res["score"], 50)

    def test_find_git_repos_discovery(self):
        self.create_mock_repo("repo-a", is_compliant=True)
        self.create_mock_repo("repo-b", is_compliant=False)
        repos = find_git_repos(self.root, max_depth=3)
        self.assertEqual(len(repos), 2)

    def test_single_repo_direct_target(self):
        repo = self.create_mock_repo("direct-repo", is_compliant=True)
        repos = find_git_repos(repo)
        self.assertEqual(repos, [repo])

    def test_formatters_output(self):
        repo = self.create_mock_repo("fmt-repo", is_compliant=True)
        results = [audit_repository(repo)]
        table_out = format_table(results)
        self.assertIn("fmt-repo", table_out)
        self.assertIn("Tier 1", table_out)

        md_out = format_markdown(results)
        self.assertIn("fmt-repo", md_out)
        self.assertIn("✅", md_out)

        summary_out = print_summary(results)
        self.assertIn("Total de Repositórios Analisados: 1", summary_out)


    def snapshot(self, repo: Path) -> dict[str, bytes]:
        return {str(path.relative_to(repo)): path.read_bytes() for path in repo.rglob("*") if path.is_file()}

    def legacy_perfect_fixture(self, name: str = "legacy-perfect") -> Path:
        repo = self.create_mock_repo(name)
        (repo / INTERFACE_SKILL).unlink()
        (repo / ".agent/INVARIANTS.md").write_text("# INVARIANTS.md\n", encoding="utf-8")
        agents = repo / "AGENTS.md"
        agents.write_text("\n".join(line for line in agents.read_text(encoding="utf-8").splitlines()
                                    if "Interface & UI Verification" not in line), encoding="utf-8")
        return repo

    def test_legacy_perfect_score_is_83_with_new_checks(self) -> None:
        result = audit_repository(self.legacy_perfect_fixture())
        self.assertEqual(result["score"], 83)
        self.assertTrue(all(not result["checks"][key] for key in INTERFACE_WEIGHTS))
        self.assertEqual(sum(INTERFACE_WEIGHTS.values()), 20)
        self.assertTrue(all(any(key in message for message in result["violations"]) for key in INTERFACE_WEIGHTS))

    def test_missing_and_altered_skill_have_distinct_checks(self) -> None:
        repo = self.create_mock_repo("skill-checks")
        skill = repo / INTERFACE_SKILL
        canonical = skill.read_bytes()
        skill.write_bytes(canonical + b"\n")
        result = audit_repository(repo)
        self.assertTrue(result["checks"]["interface_skill_installed"])
        self.assertFalse(result["checks"]["interface_skill_canonical"])
        self.assertEqual(result["score"], 97)
        skill.unlink()
        result = audit_repository(repo)
        self.assertFalse(result["checks"]["interface_skill_installed"])
        self.assertFalse(result["checks"]["interface_skill_canonical"])
        self.assertEqual(result["score"], 95)

    def test_each_guardrail_drift_fails_only_its_check(self) -> None:
        repo = self.create_mock_repo("guardrail-drift")
        path = repo / ".agent/INVARIANTS.md"
        original = path.read_text(encoding="utf-8")
        for number in range(1, 5):
            with self.subTest(guardrail=number):
                path.write_text(original.replace(f"Invariant 7.{number} (", f"Invariant 7.{number} (ALTERED ", 1), encoding="utf-8")
                result = audit_repository(repo)
                failed = {key for key in INTERFACE_WEIGHTS if not result["checks"][key]}
                self.assertEqual(failed, {f"interface_invariant_7_{number}"})
                self.assertEqual(result["score"], 98)

    def test_missing_duplicate_and_fenced_guardrails_fail(self) -> None:
        repo = self.create_mock_repo("fake-guardrails")
        path = repo / ".agent/INVARIANTS.md"
        original = path.read_text(encoding="utf-8")
        path.write_text("```markdown\n" + original + "\n```\n", encoding="utf-8")
        result = audit_repository(repo)
        self.assertTrue(all(not result["checks"][f"interface_invariant_7_{n}"] for n in range(1, 5)))
        path.write_text(original + "\n- **Invariant 7.2 (Duplicate):**\n  - Fake duplicate.\n", encoding="utf-8")
        self.assertFalse(audit_repository(repo)["checks"]["interface_invariant_7_2"])
        path.write_text(original.replace("- **Invariant 7.3", "- **Removed 7.3"), encoding="utf-8")
        self.assertFalse(audit_repository(repo)["checks"]["interface_invariant_7_3"])
        path.write_text("## 7. Adaptive Interface Verification & UI Protocol\n" + "\n".join(
            f"- **Invariant 7.{n} (Label only):**" for n in range(1, 5)), encoding="utf-8")
        result = audit_repository(repo)
        self.assertTrue(all(not result["checks"][f"interface_invariant_7_{n}"] for n in range(1, 5)))

    def test_unrelated_project_invariants_are_allowed(self) -> None:
        repo = self.create_mock_repo("custom-fences")
        path = repo / ".agent/INVARIANTS.md"
        with path.open("a", encoding="utf-8") as handle:
            handle.write("\n- Project-specific rule: retain production queue ordering.\n\n## 8. Host Rules\nDo not disrupt SSH.\n")
        self.assertEqual(audit_repository(repo)["score"], 100)

    def test_context_and_dod_must_be_active_and_in_their_sections(self) -> None:
        repo = self.create_mock_repo("active-directives")
        path = repo / "AGENTS.md"
        original = path.read_text(encoding="utf-8")
        for heading in ["Modular Context Triggers", "Falsifiable Definition of Done"]:
            with self.subTest(heading=heading):
                path.write_text(original.replace(heading, "Unrelated Examples"), encoding="utf-8")
                result = audit_repository(repo)
                key = "interface_context_on_demand" if heading == "Modular Context Triggers" else "interface_dod_dual_runtime"
                self.assertFalse(result["checks"][key])
        for fenced in ["```markdown\n" + original + "\n```", "~~~markdown\n" + original + "\n~~~", "<!--\n" + original + "\n-->"]:
            path.write_text(fenced, encoding="utf-8")
            result = audit_repository(repo)
            self.assertFalse(result["checks"]["interface_context_on_demand"])
            self.assertFalse(result["checks"]["interface_dod_dual_runtime"])
        path.write_text(original.replace("headless", "graphical"), encoding="utf-8")
        self.assertFalse(audit_repository(repo)["checks"]["interface_dod_dual_runtime"])
        path.write_text(original.replace("on-demand", "always"), encoding="utf-8")
        self.assertFalse(audit_repository(repo)["checks"]["interface_context_on_demand"])

    def test_missing_canonical_references_are_explicit_failures(self) -> None:
        repo = self.create_mock_repo("no-references")
        with patch(__name__ + ".CANONICAL_ROOT", self.root / "unavailable-reference"):
            result = audit_repository(repo)
        self.assertTrue(result["checks"]["interface_skill_installed"])
        self.assertFalse(result["checks"]["interface_skill_canonical"])
        self.assertTrue(all(not result["checks"][f"interface_invariant_7_{n}"] for n in range(1, 5)))
        self.assertTrue(any("canonical skill" in message and "FileNotFoundError" in message for message in result["violations"]))
        self.assertTrue(any("canonical invariants" in message for message in result["violations"]))

    def test_unreadable_and_invalid_utf8_contracts_fail(self) -> None:
        repo = self.create_mock_repo("unreadable-contracts")
        skill = repo / INTERFACE_SKILL
        skill.write_bytes(b"invalid \xff UTF-8")
        result = audit_repository(repo)
        self.assertFalse(result["checks"]["interface_skill_installed"])
        self.assertTrue(any("UnicodeDecodeError" in message for message in result["violations"]))
        read_bytes = Path.read_bytes

        def denied_read(path: Path) -> bytes:
            if path == CANONICAL_ROOT / INTERFACE_SKILL:
                raise PermissionError("fixture denies canonical read")
            return read_bytes(path)

        with patch.object(Path, "read_bytes", denied_read):
            result = audit_repository(repo)
        self.assertFalse(result["checks"]["interface_skill_canonical"])
        self.assertTrue(any("canonical skill" in message and "PermissionError" in message for message in result["violations"]))

    def test_malformed_agents_and_invariants_fail_their_checks(self) -> None:
        repo = self.create_mock_repo("malformed-text")
        for relative, keys in [
            ("AGENTS.md", ["interface_context_on_demand", "interface_dod_dual_runtime"]),
            (".agent/INVARIANTS.md", [f"interface_invariant_7_{n}" for n in range(1, 5)]),
        ]:
            with self.subTest(path=relative):
                path = repo / relative
                original = path.read_bytes()
                path.write_bytes(original + b"\xff")
                result = audit_repository(repo)
                self.assertTrue(all(not result["checks"][key] for key in keys))
                self.assertTrue(any("UnicodeDecodeError" in message for message in result["violations"]))
                path.write_bytes(original)

    def test_duplicate_sections_and_incomplete_canonical_blocks_fail(self) -> None:
        repo = self.create_mock_repo("duplicate-sections")
        path = repo / ".agent/INVARIANTS.md"
        with path.open("a", encoding="utf-8") as handle:
            handle.write("\n## 7. Adaptive Interface Verification & UI Protocol\n")
        result = audit_repository(repo)
        self.assertTrue(all(not result["checks"][f"interface_invariant_7_{n}"] for n in range(1, 5)))
        reference = self.root / "bad-reference"
        (reference / ".agent").mkdir(parents=True)
        (reference / ".agent/INVARIANTS.md").write_text(
            "## 7. Adaptive Interface Verification & UI Protocol\n" + "\n".join(
                f"- **Invariant 7.{n} (Label only):**" for n in range(1, 5)), encoding="utf-8")
        with patch(__name__ + ".CANONICAL_ROOT", reference):
            result = audit_repository(repo)
        self.assertTrue(any("canonical Invariant 7.1 is missing" in message for message in result["violations"]))

    def test_audit_is_read_only_and_fields_remain_compatible(self) -> None:
        repo = self.create_mock_repo("readonly-audit")
        before = self.snapshot(repo)
        result = audit_repository(repo)
        self.assertEqual(self.snapshot(repo), before)
        self.assertEqual(set(result), {"name", "path", "score", "tier", "checks", "violations"})
        self.assertTrue(all(isinstance(value, bool) for value in result["checks"].values()))
        self.assertTrue(all(result["checks"][key] for key in INTERFACE_WEIGHTS))
        expected_legacy = {"has_agents_md", "agents_high_density", "agents_fail_stop", "agents_contrast_pairs",
                           "has_agent_dir", "has_task_md", "has_notes_md", "has_archive_md", "has_invariants_md",
                           "notes_no_task_headings", "notes_has_subagent_contract", "has_single_adr", "no_legacy_adr_dir",
                           "worktrees_in_gitignore", "has_agent_hooks", "llm_gateway_in_env_example",
                           "has_bilingual_readme", "has_changelog"}
        self.assertEqual(set(result["checks"]) - set(INTERFACE_WEIGHTS), expected_legacy)

    def test_interface_diagnostics_appear_in_text_reports(self) -> None:
        result = audit_repository(self.legacy_perfect_fixture("report-details"))
        for report in [format_table([result]), format_markdown([result])]:
            self.assertIn("interface_skill_canonical", report)
            self.assertIn("interface_invariant_7_4", report)
            self.assertIn("restore", report)

    def test_cli_json_thresholds_output_and_verbose_compatibility(self) -> None:
        repo = self.legacy_perfect_fixture("cli-audit")
        before = self.snapshot(repo)
        base = [sys.executable, str(Path(__file__).resolve()), str(repo), "--no-exclude"]
        for threshold, expected in [(83, 0), (84, 1), (90, 1)]:
            result = subprocess.run(base + ["--format", "json", "--verbose", "--fail-under", str(threshold)],
                                    capture_output=True, text=True, check=False)
            self.assertEqual(result.returncode, expected, result.stderr)
            payload = json.loads(result.stdout)
            self.assertEqual(payload[0]["score"], 83)
            self.assertIn("interface_skill_canonical", payload[0]["checks"])
        output = self.root / "audit.json"
        result = subprocess.run(base + ["--format", "json", "--output", str(output)],
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(output.read_text(encoding="utf-8"))[0]["score"], 83)
        result = subprocess.run(base + ["--verbose"], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("interface_context_on_demand=False", result.stdout)
        self.assertEqual(self.snapshot(repo), before)


def run_self_tests() -> int:
    """Execute hermetic unit and verification test suite."""
    print("==> Executing audit-ecosystem-standards.py hermetic self-test suite...")
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromTestCase(TestAuditEcosystemStandards)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    return 0 if result.wasSuccessful() else 1


def main():
    parser = argparse.ArgumentParser(
        description="Audita conformidade heurística dos repositórios com o template-agent."
    )
    parser.add_argument("path", nargs="?", default="", help="Caminho raiz para escanear (padrão: ~/github ou diretório atual)")
    parser.add_argument("--dir", "-d", dest="dir_opt", default="", help="Alternativa para caminho raiz")
    parser.add_argument("--max-depth", "-m", type=int, default=4, help="Profundidade máxima de busca (padrão: 4)")
    parser.add_argument("--format", "-f", choices=["table", "markdown", "json"], default="table", help="Formato de saída")
    parser.add_argument("--output", "-o", help="Salva a saída em arquivo especificado")
    parser.add_argument("--fail-under", type=int, default=0, help="Falha com código 1 se média < N")
    parser.add_argument("--exclude", nargs="*", default=list(DEFAULT_EXCLUDED_NAMES),
                        help="Nomes de repositórios/diretórios a excluir do cálculo")
    parser.add_argument("--no-exclude", action="store_true", help="Desabilita filtros padrão de exclusão")
    parser.add_argument("--self-test", action="store_true", help="Executa suíte de testes unitários herméticos")
    parser.add_argument("--verbose", "-v", action="store_true", help="Exibe detalhes completos das checagens")

    args = parser.parse_args()

    if args.self_test:
        sys.exit(run_self_tests())

    target_dir_str = args.dir_opt or args.path or str(Path.home() / "github")
    root_path = Path(target_dir_str).expanduser().resolve()

    if not root_path.exists():
        print(f"Erro: Caminho '{root_path}' não existe.", file=sys.stderr)
        sys.exit(2)

    repo_paths = find_git_repos(root_path, args.max_depth)

    # Filter out excluded repos unless targeting a single repo directly or --no-exclude was passed
    filtered_repos: List[Path] = []
    is_direct_single_target = len(repo_paths) == 1 and repo_paths[0] == root_path

    exclusion_list = [] if args.no_exclude else [e.strip() for e in args.exclude if e and e.strip()]

    for p in repo_paths:
        if not is_direct_single_target and exclusion_list:
            if any(exc in p.name for exc in exclusion_list):
                continue
        filtered_repos.append(p)

    results = [audit_repository(r) for r in filtered_repos]
    # Sort by score descending, then by name
    results.sort(key=lambda x: (-x["score"], x["name"]))

    if args.format == "json":
        output_text = json.dumps(results, indent=2, ensure_ascii=False)
    elif args.format == "markdown":
        output_text = format_markdown(results) + "\n\n" + print_summary(results)
    else:
        output_text = format_table(results) + "\n" + print_summary(results)

    if args.verbose and args.format != "json":
        details = [f"{r['name']}: {key}={passed}" for r in results
                   for key, passed in r["checks"].items() if key in INTERFACE_WEIGHTS]
        output_text += "\n\n" + "\n".join(details)

    if args.output:
        Path(args.output).write_text(output_text, encoding="utf-8")
        print(f"Relatório gravado com sucesso em: {args.output}")
    else:
        print(output_text)

    if args.fail_under > 0 and len(results) > 0:
        avg = sum(r["score"] for r in results) / len(results)
        if avg < args.fail_under:
            print(
                f"\n[FALHA] Média de aderência ({avg:.1f}%) abaixo do limite configurado ({args.fail_under}%).",
                file=sys.stderr
            )
            sys.exit(1)


if __name__ == "__main__":
    main()
