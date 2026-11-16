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


if __name__ == "__main__":
    unittest.main()
