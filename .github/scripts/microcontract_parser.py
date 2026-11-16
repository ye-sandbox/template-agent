#!/usr/bin/env python3
"""Task-file micro-contract parser and wave/batch validator.

Backend of `verify-microcontract.sh` for the `verify-file`, `verify-waves`
and `verify-batches` commands. Output markers and exit codes are a stable
contract (parity with the original Bash implementation):

    exit 0  all validations passed
    exit 1  validation failure (or task file not found)
    exit 2  CLI usage error

Usage: microcontract_parser.py {all|waves|batches} <task-file>
"""
from __future__ import annotations

import fnmatch
import os
import re
import sys
from dataclasses import dataclass, field

TASK_TYPES = ("code", "browser-qa", "mobile-qa", "preview-mockup")

_USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
_BOLD, _GREEN, _RED, _BLUE, _RESET = (
    ("\033[1m", "\033[1;32m", "\033[1;31m", "\033[1;34m", "\033[0m")
    if _USE_COLOR
    else ("", "", "", "", "")
)


def log_info(msg: str) -> None:
    print(f"{_BLUE}==>{_RESET} {_BOLD}{msg}{_RESET}")


def log_success(msg: str) -> None:
    print(f"{_GREEN}✓{_RESET} {msg}")


def log_error(msg: str) -> None:
    print(f"{_RED}❌{_RESET} {msg}", file=sys.stderr)


# ------------------------------------------------------------------------------
# Path utilities
# ------------------------------------------------------------------------------


def normalize_path(p: str) -> str:
    p = p.strip()
    p = p[1:] if p.startswith("`") else p
    p = p[:-1] if p.endswith("`") else p
    p = p[2:] if p.startswith("./") else p
    p = p[:-1] if p.endswith("/") else p
    return p


_UI_GLOBS = (
    "*.tsx", "*.jsx", "*.svelte", "*.vue", "*.css", "*.scss", "*.html",
    "*pages/*", "*components/*", "*views/*", "proto/*",
)
_BACKEND_GLOBS = (
    "*prisma/*", "*.prisma", "*migrations/*", "*repos/*", "*repositories/*",
    "*controllers/*", "*routes/*", "*services/*", "*api/*", "*handlers/*",
    "*domain/*", "*db/*", "*models/*", "*server/*", "*middleware/*",
    "*backend/*", "*.sql", "*.py", "*.go", "*.rs", "*.rb", "*.java", "*.cs",
    "*.php",
)


def _matches_any(path: str, globs: tuple[str, ...]) -> bool:
    return any(fnmatch.fnmatchcase(path, g) for g in globs)


def classify_task_layer(task_type: str, paths: list[str]) -> str:
    if task_type in ("browser-qa", "mobile-qa", "preview-mockup"):
        return "ui-qa"
    has_ui = has_backend = False
    for p in paths:
        if _matches_any(p, _UI_GLOBS):
            has_ui = True
        elif _matches_any(p, _BACKEND_GLOBS):
            has_backend = True
    if has_ui and has_backend:
        return "mixed-stack"
    if has_ui:
        return "frontend-ui"
    if has_backend:
        return "backend-code"
    return "code"


def _glob_base(p: str) -> str:
    p = p.removesuffix("**")
    p = p.removesuffix("*")
    return p.removesuffix("/")


def paths_collide(path_a: str, path_b: str) -> bool:
    a, b = normalize_path(path_a), normalize_path(path_b)
    if not a or not b:
        return False
    if a == b or b.startswith(a + "/") or a.startswith(b + "/"):
        return True
    a_clean, b_clean = _glob_base(a), _glob_base(b)
    if a_clean and (b == a_clean or b.startswith(a_clean + "/")):
        return True
    if b_clean and (a == b_clean or a.startswith(b_clean + "/")):
        return True
    return False


# ------------------------------------------------------------------------------
# Task-file parsing
# ------------------------------------------------------------------------------

_SKIP_LINE = re.compile(r"^\s*[>|]")
_TASK_HEADER = re.compile(
    r"^\s*([-*]\s+(\[[\sxX]\]\s+)?(\*\*)?(Task:?(\*\*)?\s*)?"
    r"|###+\s*(Task\s*)?|(Task:\s*))(\[[0-9]{2}\.[0-9]+(\.[0-9]+)?\])"
)
_WAVE_TAG = re.compile(r"\[PARALLEL:\s*(W[0-9]+[0-9A-Za-z_-]*)\]")
_BATCH_TAG = re.compile(r"\[BATCH:\s*(B[0-9]+[0-9A-Za-z_-]*)\]")
_KEY = {
    k: re.compile(rf"^\s*(-\s*)?{k}:")
    for k in ("Type", "Read", "Paths", "Verify", "Depends")
}
_LIST_ITEM = re.compile(r"^\s*-\s+(.+)")
_ANY_KEY = re.compile(r"^\s*(-\s*)?[A-Za-z]+:")
_BARE_ID = re.compile(r"^\[[0-9]{2}\.[0-9]+(\.[0-9]+)?\]$")
_BLOCK_END = re.compile(r"^(---|##\s)")


@dataclass
class Task:
    task_id: str
    wave: str = ""
    batch: str = ""
    type: str = "code"
    read: list[str] = field(default_factory=list)
    paths: list[str] = field(default_factory=list)
    verify: str = ""
    depends: list[str] = field(default_factory=list)


def _split_inline(value: str) -> list[str]:
    value = normalize_path(value)
    if not value or value == "-":
        return []
    return [n for n in (normalize_path(i) for i in value.split(",")) if n]


def parse_tasks(text: str) -> list[Task]:
    tasks: list[Task] = []
    cur: Task | None = None
    section = ""  # "", "read", "paths" or "depends": which list items attach to

    def finalize() -> None:
        nonlocal cur, section
        if cur is not None:
            tasks.append(cur)
        cur, section = None, ""

    for raw in text.split("\n"):
        if _SKIP_LINE.match(raw):
            continue
        clean = raw.replace("`", "")

        # In a Depends: list, "- [XX.Y]" items look like task headers; treat as items.
        if cur is not None and section == "depends":
            item = _LIST_ITEM.match(clean)
            if item and _BARE_ID.match(item.group(1).strip()):
                cur.depends.append(item.group(1).strip())
                continue

        m = _TASK_HEADER.match(clean)
        if m:
            finalize()
            cur = Task(task_id=m.group(8))
            wave = _WAVE_TAG.search(clean)
            batch = _BATCH_TAG.search(clean)
            cur.wave = wave.group(1) if wave else ""
            cur.batch = batch.group(1) if batch else ""
            continue

        if cur is None:
            continue

        if _KEY["Type"].match(clean):
            section = ""
            cur.type = normalize_path(clean.split("Type:", 1)[1])
            continue
        if _KEY["Read"].match(clean):
            section = "read"
            cur.read.extend(_split_inline(clean.split("Read:", 1)[1]))
            continue
        if _KEY["Paths"].match(clean):
            section = "paths"
            cur.paths.extend(_split_inline(clean.split("Paths:", 1)[1]))
            continue
        if _KEY["Depends"].match(clean):
            section = "depends"
            cur.depends.extend(_split_inline(clean.split("Depends:", 1)[1]))
            continue
        if _KEY["Verify"].match(clean):
            section = ""
            cur.verify = normalize_path(clean.split("Verify:", 1)[1])
            continue

        if section:
            target = getattr(cur, section)
            item = _LIST_ITEM.match(clean)
            if item:
                value = normalize_path(item.group(1))
                if value:
                    target.append(value)
                continue
            if _ANY_KEY.match(clean):
                section = ""

        if _BLOCK_END.match(clean):
            finalize()

    finalize()
    return tasks


# ------------------------------------------------------------------------------
# Validation
# ------------------------------------------------------------------------------


def _has_contract(t: Task) -> bool:
    return bool(t.paths or t.verify or t.wave or t.batch)


def check_tag_conflicts(tasks: list[Task]) -> int:
    errors = 0
    for t in tasks:
        if t.wave and t.batch:
            log_error(
                f"Task {t.task_id} cannot declare both [PARALLEL: {t.wave}] and [BATCH: {t.batch}]"
            )
            errors += 1
    return errors


def check_contracts(tasks: list[Task]) -> tuple[int, int]:
    """Return (validated_contracts, errors)."""
    validated = errors = 0
    for t in tasks:
        if not _has_contract(t):
            continue
        task_errs = 0
        if not t.read:
            log_error(f"Task {t.task_id} missing or empty 'Read:' key")
            task_errs += 1
        if not t.paths:
            log_error(f"Task {t.task_id} missing or empty 'Paths:' key")
            task_errs += 1
        if not t.verify:
            log_error(f"Task {t.task_id} missing or empty 'Verify:' key")
            task_errs += 1
        if t.type not in TASK_TYPES:
            log_error(
                f"Task {t.task_id} has invalid 'Type:' '{t.type}' "
                "(allowed: code, browser-qa, mobile-qa, preview-mockup)"
            )
            task_errs += 1
        if task_errs:
            errors += task_errs
        else:
            validated += 1
    return validated, errors


def check_dependencies(tasks: list[Task]) -> int:
    """Rule A: every Depends: ID exists in the task file; the graph is acyclic."""
    errors = 0
    ids = {t.task_id for t in tasks}
    graph: dict[str, list[str]] = {}
    for t in tasks:
        if not t.depends:
            continue
        for dep in t.depends:
            if dep not in ids:
                log_error(f"Task {t.task_id} 'Depends:' references unknown task {dep}")
                errors += 1
        graph.setdefault(t.task_id, []).extend(d for d in t.depends if d in ids)

    state: dict[str, int] = {}  # 1 = visiting, 2 = done
    reported: set[frozenset[str]] = set()

    def visit(node: str, stack: list[str]) -> None:
        nonlocal errors
        state[node] = 1
        stack.append(node)
        for nxt in graph.get(node, []):
            if state.get(nxt) == 1:
                cycle = stack[stack.index(nxt):]
                key = frozenset(cycle)
                if key not in reported:
                    reported.add(key)
                    log_error("Dependency cycle: " + " -> ".join(cycle + [nxt]))
                    errors += 1
            elif nxt not in state:
                visit(nxt, stack)
        stack.pop()
        state[node] = 2

    for node in list(graph):
        if node not in state:
            visit(node, [])
    return errors


def check_waves(tasks: list[Task], task_file: str) -> int:
    log_info("Verifying parallel wave mutual disjointness...")
    entries = [
        (t.wave, t.task_id, p)
        for t in tasks
        if t.wave and _has_contract(t)
        for p in t.paths
    ]
    conflicts = 0
    for i, (wave_i, task_i, path_i) in enumerate(entries):
        for wave_j, task_j, path_j in entries[i + 1:]:
            if wave_i == wave_j and task_i != task_j and paths_collide(path_i, path_j):
                log_error(f"Parallel Wave Conflict in [{wave_i}]:")
                print(f"   Task {task_i} path: '{path_i}'", file=sys.stderr)
                print("   collides with", file=sys.stderr)
                print(f"   Task {task_j} path: '{path_j}'", file=sys.stderr)
                conflicts += 1
    if conflicts:
        log_error(f"Found {conflicts} parallel wave path collision(s) in {task_file}")
    else:
        log_success(
            "Parallel wave disjointness verified: zero overlapping mutable paths in identical waves"
        )
    return conflicts


def check_batches(tasks: list[Task], task_file: str) -> int:
    log_info("Verifying sequential batch constraints ([BATCH: Bx])...")
    batches: dict[str, list[tuple[str, str]]] = {}  # id -> [(type, layer)]
    for t in tasks:
        if t.batch and _has_contract(t):
            batches.setdefault(t.batch, []).append(
                (t.type, classify_task_layer(t.type, t.paths))
            )

    batch_errors = 0
    for b_id in sorted(batches):
        members = batches[b_id]
        layers = {layer for _, layer in members}
        type_mismatch = len({ty for ty, _ in members}) > 1
        has_ui_qa = "ui-qa" in layers
        has_frontend = bool(layers & {"frontend-ui", "mixed-stack"})
        has_backend = bool(layers & {"backend-code", "mixed-stack"})

        if not 2 <= len(members) <= 4:
            log_error(
                f"Sequential Batch Cardinality Violation in [BATCH: {b_id}]: contains "
                f"{len(members)} subtask(s); must group between 2 and 4 sequential subtasks."
            )
            batch_errors += 1
        if type_mismatch or (has_ui_qa and has_backend) or (has_frontend and has_backend):
            log_error(
                f"Sequential Batch Layer Violation in [BATCH: {b_id}]: mixes incompatible "
                "architectural layers (e.g. Backend/DB code with Frontend/UI or "
                "browser-qa/mobile-qa). Split into separate batches per layer."
            )
            batch_errors += 1

    if batch_errors:
        log_error(f"Found {batch_errors} sequential batch violation(s) in {task_file}")
    else:
        log_success(
            "Sequential batches verified: all [BATCH: Bx] groups respect 2-4 cardinality "
            "and single-layer boundaries"
        )
    return batch_errors


def validate_task_file(task_file: str, mode: str = "all") -> int:
    if not task_file or not os.path.isfile(task_file):
        log_error(f"Task file not found: {task_file}")
        return 1

    log_info(f"Analyzing task definitions in: {task_file}")
    with open(task_file, encoding="utf-8") as fh:
        tasks = parse_tasks(fh.read())

    errors = check_tag_conflicts(tasks)
    errors += check_dependencies(tasks)
    validated = 0
    if mode == "all":
        validated, contract_errors = check_contracts(tasks)
        errors += contract_errors

    if mode in ("all", "waves"):
        errors += check_waves(tasks, task_file)
    if mode in ("all", "batches"):
        errors += check_batches(tasks, task_file)
    if mode == "all":
        log_success(f"Task file validation completed ({validated} micro-contract(s) audited)")

    return 1 if errors else 0


def main(argv: list[str]) -> int:
    sys.stdout.reconfigure(line_buffering=True)  # keep stdout/stderr interleaving stable
    if len(argv) != 3 or argv[1] not in ("all", "waves", "batches"):
        print(__doc__, file=sys.stderr)
        return 2
    return validate_task_file(argv[2], argv[1])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
