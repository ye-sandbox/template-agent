# Brownfield Agent-Driven Development (ADD) Template

🌐 **English | [Português](README.pt-br.md)**

> 🧱 **Tailored for Legacy Codebases and Existing Repositories.**  
> A governance framework designed to introduce AI coding agents (Antigravity, Claude Code, Cursor, Windsurf, Roo Code, Aider, etc.) safely into existing production repositories without breaking implicit contracts or introducing silent regressions.

---

## 💡 Why a Dedicated Template for Legacies?

Working with AI agents in scratch projects (Greenfield) differs fundamentally from legacy codebases (Brownfield):
- **Greenfield:** The agent designs architectures from scratch, authors ADRs, and defines new contracts.
- **Brownfield:** Decisions were already made. The agent must proceed with surgical restraint (*Chesterton's Fence*), write **characterization tests** before refactoring, and strictly respect legacy system contracts.

---

## 📁 Template Structure

```text
├── AGENTS.md                 # Constitution for legacy code (non-regression rules, surgical scope)
├── install.sh                # Script to inject this template into any existing repository
└── .agent/
    ├── TASK.md               # Active task (starting with Task 00 Discovery)
    ├── INVARIANTS.md         # Untouchable behaviors, frozen dependencies, and justified quirks
    ├── NOTES.md              # Mapped active contracts and recent gotchas
    └── ARCHIVE.md            # Completed task history to preserve lean context
```

---

## 🚀 How to Inject this Template into an Existing Repository

### Option 1: Automated Script (Recommended)

From the root of your existing legacy project, run the one-line installer via `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash
```

> 💡 **Tip for automation or CI:** Pass `-y` to bypass interactive prompts:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- -y
> ```
> To target a specific folder:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- ./path/to/project
> ```

> 🔒 **Enterprise / Local-Only Mode (Stealth):**
> If working in an enterprise codebase where you cannot or do not want to commit agentic governance files:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield/install.sh | bash -s -- --local-only
> ```
> This automatically excludes `.agent/` and `AGENTS.md` via `.git/info/exclude` (leaving `.gitignore` untouched and git status 100% clean) and injects strict stealth guardrails.

*Or run locally from a cloned copy of the `brownfield` branch:*
```bash
./install.sh /path/to/your-legacy-project
# or with stealth mode:
./install.sh --local-only /path/to/your-legacy-project
```

### Option 2: Manual Copy
Copy `AGENTS.md` and the `.agent/` directory directly into the root of your existing project.

---

## 🔄 The Adoption Lifecycle: Task 00 (Discovery)

Once template files are injected into your legacy project:

1. Open your AI coding environment at the project root.
2. Send the initial kickoff prompt:
   > *"Read AGENTS.md and .agent/TASK.md. Present your implementation plan for Task [00.1] Project Discovery and Audit before modifying any code."*
3. The agent will:
   - Identify languages, versions, and official package managers from manifests (`package.json`, `pyproject.toml`, etc.).
   - Record actual test, lint, and build commands in `AGENTS.md`.
   - Map key entrypoints and environment variables.
   - Record initial critical quirks in `.agent/INVARIANTS.md`.
4. Once Discovery is complete, your repository is fully calibrated for safe tasks, bugfixes, and refactorings!

---

## 🛡️ Core Rules of this Template

1. **Characterization Tests:** If a legacy function lacks test coverage and requires modification, write a test proving current behavior before touching application logic.
2. **No Opportunistic Refactoring:** Keep diffs surgical. Do not reformat untouched files or alter adjacent code styles.
3. **Respect Invariants:** Consult `INVARIANTS.md` before altering logic that seems suboptimal or redundant.
