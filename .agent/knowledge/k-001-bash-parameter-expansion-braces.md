---
id: "k-001"
title: "Quote Empty Braces in Bash Parameter Expansion Defaults"
date: 2026-10-17
tags:
  - "bash"
  - "shell"
  - "json"
  - "parameter-expansion"
severity: "medium"
affected_components:
  - "benchmarks/scripts/stream-telemetry.sh"
symptoms:
  - "extra trailing brace appended to variable"
  - "json.loads failure on default parameter expansion"
  - "malformed json string ending with double closing braces"
---

## Problem / Symptom

When defining a default value containing curly braces in bash parameter expansion, writing `${1:-{}}` causes bash's parser to match the first `}` as the closing delimiter of the parameter expansion expression `${...}`. The subsequent literal `}` character is treated as trailing literal text and appended to the variable value:

```bash
bash -c 'EXTRA="${1:-{}}"; echo "$EXTRA"' -- '{"foo": "bar"}'
# Outputs: {"foo": "bar"}}
```

When passing JSON objects to tools like `python3 -c "import json; json.loads(...)"` or `jq`, the trailing `}` triggers a fatal JSON decode error (`json.decoder.JSONDecodeError: Extra data`).

## Approved Solution

Always isolate or quote empty curly braces when specifying defaults in bash parameter expansion:

```bash
# Option A: Isolate the default value in a variable (Recommended for readability)
DEFAULT_EXTRA="{}"
EXTRA_JSON="${4:-$DEFAULT_EXTRA}"

# Option B: Quote the default string literal within the expansion
EXTRA_JSON="${4:-"{}"}"
```

Both options ensure bash correctly treats the entire `{}` sequence as the parameter default without appending dangling closing braces.

## What NEVER to Do

- **NEVER** use unquoted `${VAR:-{}}` in shell scripts when dealing with JSON objects or dictionary strings.
- **NEVER** attempt naive string replacement (`sed 's/}}$/}/'`) to strip accidental trailing braces instead of fixing the root parameter expansion syntax.

## Verification

```bash
bash -c 'DEF="{}"; EXTRA="${1:-$DEF}"; echo "$EXTRA"' -- '{"foo": "bar"}'
# Correct output: {"foo": "bar"}
```
