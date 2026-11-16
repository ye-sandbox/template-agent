#!/usr/bin/env python3
"""Hermetic unit tests for microcontract_parser validation rules."""
import contextlib
import io
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import microcontract_parser as mp  # noqa: E402


def run(text: str, mode: str = "all") -> tuple[int, str]:
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "TASK.md")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = mp.validate_task_file(path, mode)
        return code, out.getvalue() + err.getvalue()


def task(tid: str, depends: str | None = None, paths: str = "a.md") -> str:
    dep = f"- Depends: {depends}\n" if depends is not None else ""
    return (
        f"- **Task:** `[{tid}]` Title\n- Type: code\n- Read: x.md\n"
        f"- Paths: {paths}\n{dep}- Verify: true\n\n"
    )


class DependsRule(unittest.TestCase):
    def test_no_depends_passes(self):
        self.assertEqual(run(task("01.1") + task("01.2", paths="b.md"))[0], 0)

    def test_valid_depends_inline_and_list(self):
        text = task("01.1", paths="a.md") + task("01.2", paths="b.md") + (
            "- **Task:** `[01.3]` T\n- Type: code\n- Read: x.md\n- Paths: c.md\n"
            "- Depends:\n  - [01.1]\n  - [01.2]\n- Verify: true\n"
        )
        self.assertEqual(run(text)[0], 0)
        self.assertEqual(run(task("01.1") + task("01.2", "[01.1], [01.1]", "b.md"))[0], 0)

    def test_unknown_id_rejected(self):
        code, out = run(task("01.1", "[09.9]"))
        self.assertEqual(code, 1)
        self.assertIn("unknown task [09.9]", out)

    def test_cycle_rejected(self):
        code, out = run(task("01.1", "[01.2]") + task("01.2", "[01.1]", "b.md"))
        self.assertEqual(code, 1)
        self.assertIn("Dependency cycle", out)

    def test_self_dependency_rejected(self):
        code, out = run(task("01.1", "[01.1]"))
        self.assertEqual(code, 1)
        self.assertIn("Dependency cycle", out)

    def test_depends_list_not_leaked_into_paths(self):
        tasks = mp.parse_tasks(task("01.1") + task("01.2", "[01.1]", "b.md"))
        self.assertEqual(tasks[1].paths, ["b.md"])
        self.assertEqual(tasks[1].depends, ["[01.1]"])


def wave_task(tid: str, paths: str, wave: str = "W1") -> str:
    return (
        f"- **Task:** `[{tid}]` [PARALLEL: {wave}] Title\n- Type: code\n- Read: x.md\n"
        f"- Paths: {paths}\n- Verify: true\n\n"
    )


class SerializedFilesRule(unittest.TestCase):
    def test_clean_wave_passes(self):
        self.assertEqual(run(wave_task("01.1", "a.md") + wave_task("01.2", "b.md"))[0], 0)

    def test_denied_files_rejected(self):
        for f in ("CHANGELOG.md", ".agent/TASK.md", ".agent/NOTES.md", "yarn.lock",
                  "web/package-lock.json", "uv.lock"):
            with self.subTest(f=f):
                code, out = run(wave_task("01.1", f) + wave_task("01.2", "b.md"))
                self.assertEqual(code, 1)
                self.assertIn("serialized shared file", out)

    def test_non_wave_task_may_list_them(self):
        self.assertEqual(run(task("01.1", paths="CHANGELOG.md"))[0], 0)

    def test_batch_task_may_list_them(self):
        text = "".join(
            f"- **Task:** `[01.{i}]` [BATCH: B1] T\n- Type: code\n- Read: x.md\n"
            f"- Paths: CHANGELOG.md\n- Verify: true\n\n" for i in (1, 2)
        )
        self.assertEqual(run(text)[0], 0)


def batch_task(tid: str, paths: str, depends: str | None = None) -> str:
    dep = f"- Depends: {depends}\n" if depends is not None else ""
    return (
        f"- **Task:** `[{tid}]` [BATCH: B1] T\n- Type: code\n- Read: x.md\n"
        f"- Paths: {paths}\n{dep}- Verify: true\n\n"
    )


class BatchWaveCollisionRule(unittest.TestCase):
    def batch(self, depends=None):
        return batch_task("01.1", "src/a.py", depends) + batch_task("01.2", "src/b.py")

    def test_disjoint_passes(self):
        text = self.batch() + wave_task("01.3", "docs/x.md")
        self.assertEqual(run(text)[0], 0)

    def test_collision_rejected(self):
        code, out = run(self.batch() + wave_task("01.3", "src/a.py"))
        self.assertEqual(code, 1)
        self.assertIn("without a 'Depends:' link", out)

    def test_directory_collision_rejected(self):
        self.assertEqual(run(self.batch() + wave_task("01.3", "src"))[0], 1)

    def test_direct_depends_allows(self):
        self.assertEqual(run(self.batch("[01.3]") + wave_task("01.3", "src/a.py"))[0], 0)

    def test_reverse_depends_allows(self):
        wave = wave_task("01.3", "src/a.py").replace("- Verify", "- Depends: [01.1]\n- Verify")
        self.assertEqual(run(self.batch() + wave)[0], 0)

    def test_transitive_depends_allows(self):
        mid = task("01.4", depends="[01.3]", paths="m.md")
        text = self.batch("[01.4]") + mid + wave_task("01.3", "src/a.py")
        self.assertEqual(run(text)[0], 0)

    def test_wave_vs_wave_unaffected(self):
        text = wave_task("01.1", "a.md", "W1") + wave_task("01.2", "b.md", "W2")
        self.assertEqual(run(text)[0], 0)


if __name__ == "__main__":
    unittest.main()
