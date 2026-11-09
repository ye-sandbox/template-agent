"""Disposable opt-in migration fixtures; never discover or mutate real projects."""
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1]


def load_script(name):
    spec = importlib.util.spec_from_file_location(name.replace('-', '_'), SCRIPTS / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


migration = load_script('apply-governance-standards')
auditor = load_script('audit-ecosystem-standards')


class TestInterfaceMigration(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'project'
        self.repo.mkdir()
        (self.repo / '.git').mkdir()
        self.agents = self.repo / 'AGENTS.md'
        self.agents.write_bytes(
            b'# Project rules\n\n[P0] Keep project data.\n\n'
            b'## Fail-Stop Protocol\n\nStop after **2 consecutive failures**.\n\n'
            b'## Contrast Pairs\n\nBAD: remove project rules.\n\n'
            b'## Modular Context Triggers\n\n- Read PROJECT.md for project context.\n\n'
            b'## Falsifiable Definition of Done (DoD)\n\n- [ ] Run project checks.\n'
        )
        self.rules = self.repo / '.agent/INVARIANTS.md'
        self.rules.parent.mkdir()
        self.rules.write_bytes(b'# Project invariants\n\n## Custom safety\n\n- Never delete project fixtures.\n')
        (self.repo / 'PROJECT.md').write_bytes(b'Project-specific context\x00\xff')

    def snapshot(self, root=None):
        root = root or self.repo
        return {str(path.relative_to(root)): os.readlink(path) if path.is_symlink()
                else None if path.is_dir() else path.read_bytes()
                for path in root.rglob('*')}

    def apply(self, **kwargs):
        return migration.apply_standards_to_repo(self.repo, include_interface_contracts=True, **kwargs)

    def assert_compliant(self):
        checks, violations = auditor.audit_interface_contracts(self.repo)
        self.assertTrue(all(checks.values()), violations)

    def assert_blocked(self, diagnostic):
        before = self.snapshot()
        for dry_run in (True, False):
            with self.subTest(dry_run=dry_run):
                actions = self.apply(dry_run=dry_run)
                self.assertEqual(len(actions), 1, actions)
                self.assertIn('Blocked interface migration:', actions[0])
                self.assertIn(diagnostic, actions[0])
                self.assertIn('reconcile and retry', actions[0])
                self.assertEqual(self.snapshot(), before)

    def test_install_passes_auditor_and_preserves_custom_bytes(self):
        agents, rules = self.agents.read_bytes(), self.rules.read_bytes()
        unrelated = (self.repo / 'PROJECT.md').read_bytes()
        self.assertTrue(self.apply())
        self.assert_compliant()
        self.assertIn(agents.split(b'## Modular Context')[0], self.agents.read_bytes())
        self.assertIn(b'- Read PROJECT.md for project context.', self.agents.read_bytes())
        self.assertIn(b'- [ ] Run project checks.', self.agents.read_bytes())
        self.assertTrue(self.rules.read_bytes().startswith(rules))
        self.assertEqual((self.repo / 'PROJECT.md').read_bytes(), unrelated)
        self.assertEqual((self.repo / migration.INTERFACE_SKILL).read_bytes(),
                         (migration.CANONICAL_ROOT / migration.INTERFACE_SKILL).read_bytes())

    def test_dry_run_and_second_run_write_nothing(self):
        before = self.snapshot()
        self.assertTrue(self.apply(dry_run=True))
        self.assertEqual(self.snapshot(), before)
        self.apply()
        after = self.snapshot()
        self.assertEqual(self.apply(), [])
        self.assertEqual(self.snapshot(), after)
        self.assertEqual(self.apply(dry_run=True), [])

    def test_default_mode_remains_identical_to_explicit_false(self):
        import shutil
        copy = self.root / 'copy'
        shutil.copytree(self.repo, copy)
        self.assertEqual(migration.apply_standards_to_repo(self.repo),
                         migration.apply_standards_to_repo(copy, include_interface_contracts=False))
        self.assertEqual(self.snapshot(), self.snapshot(copy))
        self.assertFalse((self.repo / migration.INTERFACE_SKILL).exists())
        self.assertNotIn(b'Invariant 7.1', self.rules.read_bytes())

    def test_missing_invariants_file_is_created(self):
        self.rules.unlink()
        self.apply()
        self.assert_compliant()

    def test_missing_agents_blocks_instead_of_inventing_project_rules(self):
        self.agents.unlink()
        self.assert_blocked('AGENTS.md: create project governance')

    def test_absent_sections_are_added(self):
        self.agents.write_text('# Rules\n[P0] Keep data\nFail-Stop: two failures\nBAD: delete data\n')
        self.apply()
        self.assert_compliant()

    def test_partial_adoption_adds_only_missing_contracts(self):
        self.apply()
        original = self.rules.read_text()
        block = auditor.invariant_blocks(original)['7.2']
        self.rules.write_text(original.replace(block, ''))
        self.agents.write_text(self.agents.read_text().replace(migration.INTERFACE_DOD, ''))
        self.apply()
        self.assert_compliant()
        self.assertEqual(self.apply(), [])
        self.assertEqual(self.rules.read_text().count('Invariant 7.1'), 1)

    def test_complete_hub_contracts_are_unchanged(self):
        for path in (Path('AGENTS.md'), Path('.agent/INVARIANTS.md'), migration.INTERFACE_SKILL):
            target = self.repo / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes((migration.CANONICAL_ROOT / path).read_bytes())
        before = self.snapshot()
        self.assertEqual(self.apply(), [])
        self.assertEqual(self.snapshot(), before)

    def test_custom_skill_blocks_all_writes_including_legacy_migration(self):
        target = self.repo / migration.INTERFACE_SKILL
        target.parent.mkdir(parents=True)
        target.write_bytes(b'# Custom interface testing\nDo not replace.\n')
        self.agents.write_text('# Legacy governance needing migration\n')
        self.assert_blocked('compare custom skill')

    def test_divergent_invariant_blocks(self):
        self.apply()
        self.rules.write_text(self.rules.read_text().replace('terminated immediately', 'kept running'))
        self.assert_blocked('Invariant 7.4: reconcile custom text')

    def test_duplicate_invariant_blocks(self):
        self.apply()
        block = auditor.invariant_blocks(self.rules.read_text())['7.2']
        self.rules.write_text(self.rules.read_text() + '\n' + block + '\n')
        self.assert_blocked('Invariant 7.2: consolidate duplicate')

    def test_custom_section_seven_is_never_repurposed(self):
        self.rules.write_text(self.rules.read_text() + '\n## 7. Project safety\n\n- Retain this fence.\n')
        self.assert_blocked('section 7 is project-specific')

    def test_misplaced_invariant_is_not_duplicated(self):
        self.rules.write_text(self.rules.read_text() + '\n- **Invariant 7.1 (Custom):**\n  - Keep this.\n')
        self.assert_blocked('move existing Invariant 7')

    def test_custom_agents_directives_block(self):
        for directive, marker in (
            ('- [ ] Interface & UI verification: use only custom browser tools.', '- [ ] Run project checks.'),
            ('- Interface skill: read a custom skill for UI.', '- Read PROJECT.md for project context.'),
            ('- [ ] Interface & UI verification: never use T3 Code or headless tests.', '- [ ] Run project checks.'),
            ('- Interface skill: never load `.agent/skills/interface-testing/SKILL.md` on-demand.', '- Read PROJECT.md for project context.'),
        ):
            with self.subTest(directive=directive):
                original = self.agents.read_bytes()
                self.agents.write_text(self.agents.read_text().replace(marker, directive + '\n' + marker))
                self.assert_blocked('custom or duplicate interface directives')
                self.agents.write_bytes(original)

    def test_indented_code_is_not_an_active_context_directive(self):
        self.agents.write_text(self.agents.read_text().replace(
            '- Read PROJECT.md for project context.',
            '    ' + migration.INTERFACE_CONTEXT + '\n- Read PROJECT.md for project context.'))
        self.assert_blocked('custom or duplicate interface directives')

    def test_misplaced_verification_contract_blocks(self):
        self.agents.write_text(self.agents.read_text() + '\n## Custom checks\n\n'
                               '- [ ] UI verification: use our custom tool.\n')
        self.assert_blocked('custom interface verification checkboxes')

    def test_duplicate_sections_block(self):
        for heading in ('Modular Context Triggers', 'Falsifiable Definition of Done', migration.INTERFACE_HEADING):
            with self.subTest(heading=heading):
                path = self.rules if heading == migration.INTERFACE_HEADING else self.agents
                original = path.read_bytes()
                path.write_bytes(original + (f'\n## {heading}\n\n## {heading}\n').encode())
                self.assert_blocked('duplicate sections')
                path.write_bytes(original)

    def test_custom_dod_heading_blocks(self):
        self.agents.write_text(self.agents.read_text().replace('Falsifiable Definition of Done (DoD)', 'Project DoD'))
        self.assert_blocked('custom DoD heading')

    def test_examples_and_comments_are_not_active_contracts(self):
        self.agents.write_text(self.agents.read_text() + '\n```md\n## Modular Context Triggers\nCustom interface skill\n```\n'
                               '<!--\n## Falsifiable Definition of Done\n-->\n')
        self.rules.write_text(self.rules.read_text() + '\n~~~md\n## 7. Custom example\n~~~\n')
        self.apply()
        self.assert_compliant()

    def test_unterminated_examples_block(self):
        self.agents.write_text(self.agents.read_text() + '\n```md\n')
        self.assert_blocked('unterminated Markdown')

    def test_crlf_invariants_preserve_original_bytes(self):
        original = self.rules.read_bytes().replace(b'\n', b'\r\n')
        self.rules.write_bytes(original)
        self.apply()
        self.assertTrue(self.rules.read_bytes().startswith(original))
        self.assert_compliant()
        self.assertEqual(self.apply(), [])

    def test_symlink_destinations_and_ancestors_block(self):
        for relative in ('AGENTS.md', '.agent/INVARIANTS.md', '.agent', '.agent/skills',
                         '.agent/skills/interface-testing', str(migration.INTERFACE_SKILL)):
            with self.subTest(relative=relative):
                # Each fixture gets an independent repository, avoiding symlink traversal during cleanup.
                import shutil
                clone = self.root / 'clone'
                shutil.copytree(self.repo, clone)
                old_repo = self.repo
                self.repo = clone
                target = clone / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                outside = self.root / 'outside'
                outside.mkdir(exist_ok=True)
                if target.is_dir():
                    shutil.rmtree(target)
                else:
                    target.unlink(missing_ok=True)
                target.symlink_to(outside, target_is_directory=True)
                before_outside = self.snapshot(outside)
                self.assert_blocked('symlink')
                self.assertEqual(self.snapshot(outside), before_outside)
                self.repo = old_repo
                shutil.rmtree(clone)

    def test_nonregular_and_invalid_utf8_contracts_block(self):
        self.rules.write_bytes(b'\xff\x00')
        self.assert_blocked('readable UTF-8')
        self.rules.unlink()
        self.rules.mkdir()
        self.assert_blocked('expected a file')

    def test_read_failure_and_missing_canonical_source_block(self):
        original = Path.read_bytes
        def fail(path):
            if path == self.agents:
                raise PermissionError('fixture permission error')
            return original(path)
        # Snapshot outside the mock because it deliberately cannot read AGENTS.
        before = self.snapshot()
        with patch.object(Path, 'read_bytes', fail):
            self.assertIn('PermissionError', self.apply()[0])
        self.assertEqual(self.snapshot(), before)
        with patch.object(migration, 'CANONICAL_ROOT', self.root / 'missing'):
            self.assert_blocked('canonical interface-testing skill')

    def cli(self, *args):
        return subprocess.run([sys.executable, str(SCRIPTS / 'apply-governance-standards.py'), *args],
                              capture_output=True, text=True, timeout=20)

    def test_cli_opt_in_dry_run_filters_and_idempotency(self):
        before = self.snapshot()
        args = ['--dir', str(self.root), '--repo', 'project', '--no-exclude', '--include-interface-contracts']
        result = self.cli(*args, '--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.snapshot(), before)
        self.assertIn('Install interface contract:', result.stdout)
        result = self.cli(*args)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assert_compliant()
        after = self.snapshot()
        result = self.cli(*args)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('Install interface contract:', result.stdout)
        self.assertEqual(self.snapshot(), after)

    def test_cli_conflict_returns_failure_with_diagnostic(self):
        target = self.repo / migration.INTERFACE_SKILL
        target.parent.mkdir(parents=True)
        target.write_text('custom')
        before = self.snapshot()
        result = self.cli(str(self.repo), '--include-interface-contracts')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn('Blocked interface migration:', result.stdout)
        self.assertNotIn('Aplicação concluída com sucesso', result.stdout)
        self.assertEqual(self.snapshot(), before)

    def test_cli_default_does_not_install_interface_contracts(self):
        result = self.cli(str(self.repo))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.repo / migration.INTERFACE_SKILL).exists())
        self.assertNotIn('Invariant 7.1', self.rules.read_text())
        self.assertIn('--include-interface-contracts', self.cli('--help').stdout)
