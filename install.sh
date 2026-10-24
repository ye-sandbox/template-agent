#!/usr/bin/env bash
# ==============================================================================
# Brownfield Template Installer for AI Coding Agents
# Supports local and remote execution (via curl | bash)
# ==============================================================================
set -euo pipefail

FORCE_YES=false
LOCAL_ONLY=false
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|-f|--force)
            FORCE_YES=true
            shift
            ;;
        -l|--local-only|--stealth)
            LOCAL_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: install.sh [-y|--yes|-f|--force] [-l|--local-only|--stealth] [TARGET_DIR]"
            echo ""
            echo "Options:"
            echo "  -l, --local-only, --stealth  Configure stealth mode for enterprise/shared repos (.git/info/exclude + stealth guardrails)"
            echo "  -y, --yes, -f, --force       Overwrite files without interactive confirmation"
            echo "  -h, --help                   Show this help message"
            exit 0
            ;;
        *)
            if [ -z "$TARGET_DIR" ]; then
                TARGET_DIR="$1"
            else
                echo "⚠️  Extra argument ignored: $1"
            fi
            shift
            ;;
    esac
done

TARGET_DIR="${TARGET_DIR:-.}"
mkdir -p "$TARGET_DIR/.agent"
RESOLVED_TARGET="$(cd "$TARGET_DIR" && pwd -P)"

# Remote repository URL for piped execution
TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-https://raw.githubusercontent.com/ye-sandbox/template-agent/brownfield}"

# Detect execution mode (local vs remote)
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd -P)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/AGENTS.md" ] && [ -d "$SCRIPT_DIR/.agent" ]; then
    INSTALL_MODE="local"
else
    INSTALL_MODE="remote"
fi

echo "======================================================="
echo " Brownfield Template Installer (ADD for Legacies)"
echo " Destination: $RESOLVED_TARGET"
echo " Mode:        $([ "$INSTALL_MODE" = "local" ] && echo "Local ($SCRIPT_DIR)" || echo "Remote ($TEMPLATE_REPO_URL)")"
if [ "$LOCAL_ONLY" = true ]; then
    echo " Profile:     Stealth / Local-Only (Enterprise Guardrails)"
fi
echo "======================================================="

# Helper to copy (local) or download (remote) files
fetch_file() {
    local rel_path="$1"
    local dest_path="$2"

    if [ "$INSTALL_MODE" = "local" ]; then
        cp "$SCRIPT_DIR/$rel_path" "$dest_path"
    else
        local url="${TEMPLATE_REPO_URL}/${rel_path}"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$url" -o "$dest_path"
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$dest_path" "$url"
        else
            echo "❌ Error: 'curl' or 'wget' is required to download template files." >&2
            exit 1
        fi
    fi
}

# Helper for interactive confirmations (safe with piped execution)
ask_confirm() {
    local prompt="$1"
    local reply=""

    if [ "$FORCE_YES" = true ]; then
        return 0
    fi

    if [ -c /dev/tty ]; then
        read -p "$prompt (y/N): " -r reply </dev/tty || reply=""
    elif [ -t 0 ]; then
        read -p "$prompt (y/N): " -r reply || reply=""
    else
        echo "⚠️  Non-interactive terminal detected. Retaining existing file."
        return 1
    fi

    if [[ "$reply" =~ ^[yYsS]$ ]]; then
        return 0
    else
        return 1
    fi
}

# 1. Install AGENTS.md
if [ -f "$RESOLVED_TARGET/AGENTS.md" ]; then
    echo "⚠️  Warning: 'AGENTS.md' already exists in $RESOLVED_TARGET."
    if ask_confirm "Overwrite existing AGENTS.md?"; then
        fetch_file "AGENTS.md" "$RESOLVED_TARGET/AGENTS.md"
        echo "✅ AGENTS.md successfully updated."
    else
        echo "ℹ️  Retaining existing AGENTS.md."
    fi
else
    fetch_file "AGENTS.md" "$RESOLVED_TARGET/AGENTS.md"
    echo "✅ AGENTS.md installed."
fi

# 2. Install files into .agent directory
AGENT_FILES=("INVARIANTS.md" "ECOSYSTEM.md" "TASK.md" "NOTES.md" "ARCHIVE.md")

for file in "${AGENT_FILES[@]}"; do
    dest="$RESOLVED_TARGET/.agent/$file"
    if [ -f "$dest" ]; then
        if [ "$FORCE_YES" = true ]; then
            fetch_file ".agent/$file" "$dest"
            echo "✅ .agent/$file updated (--force)."
        else
            echo "ℹ️  $file already exists in .agent/. Retaining existing file."
        fi
    else
        fetch_file ".agent/$file" "$dest"
        echo "✅ .agent/$file installed."
    fi
done

# 3. Install architectural decision log into docs/adr
mkdir -p "$RESOLVED_TARGET/docs/adr"
dest_decisions="$RESOLVED_TARGET/docs/adr/decisions.md"
if [ -f "$dest_decisions" ]; then
    if [ "$FORCE_YES" = true ]; then
        fetch_file "docs/adr/decisions.md" "$dest_decisions"
        echo "✅ docs/adr/decisions.md updated (--force)."
    else
        echo "ℹ️  decisions.md already exists in docs/adr/. Retaining existing file."
    fi
else
    fetch_file "docs/adr/decisions.md" "$dest_decisions"
    echo "✅ docs/adr/decisions.md installed."
fi

# 4. Install knowledge base schema, template, and canonical cards into .agent/knowledge
mkdir -p "$RESOLVED_TARGET/.agent/knowledge"
KNOWLEDGE_FILES=("000-schema.md" "k-000-template.md" "k-001-characterization-test-state-leakage.md")

for file in "${KNOWLEDGE_FILES[@]}"; do
    dest="$RESOLVED_TARGET/.agent/knowledge/$file"
    if [ -f "$dest" ]; then
        if [ "$FORCE_YES" = true ]; then
            fetch_file ".agent/knowledge/$file" "$dest"
            echo "✅ .agent/knowledge/$file updated (--force)."
        else
            echo "ℹ️  $file already exists in .agent/knowledge/. Retaining existing file."
        fi
    else
        fetch_file ".agent/knowledge/$file" "$dest"
        echo "✅ .agent/knowledge/$file installed."
    fi
done

# 5. Apply Local-Only / Stealth Mode configurations if requested
if [ "$LOCAL_ONLY" = true ]; then
    # 4.1 Exclude files in .git/info/exclude
    if command -v git >/dev/null 2>&1 && git -C "$RESOLVED_TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        REPO_ROOT="$(git -C "$RESOLVED_TARGET" rev-parse --show-toplevel)"
        GIT_DIR="$(git -C "$RESOLVED_TARGET" rev-parse --git-dir)"
        [[ "$GIT_DIR" != /* ]] && GIT_DIR="$REPO_ROOT/$GIT_DIR"
        EXCLUDE_FILE="$GIT_DIR/info/exclude"

        mkdir -p "$(dirname "$EXCLUDE_FILE")"
        touch "$EXCLUDE_FILE"

        REL_PREFIX="$(git -C "$RESOLVED_TARGET" rev-parse --show-prefix)"

        for entry in "${REL_PREFIX}AGENTS.md" "${REL_PREFIX}.agent/" "${REL_PREFIX}docs/adr/"; do
            pattern="/$entry"
            if ! grep -Fxq "$pattern" "$EXCLUDE_FILE"; then
                echo "$pattern" >> "$EXCLUDE_FILE"
            fi
        done
        echo "🔒 Configured $EXCLUDE_FILE (local-only exclude active)."
    else
        echo "⚠️  Note: Target directory is not a Git repository. Git exclude was not configured."
    fi

    # 3.2 Inject Stealth Guardrail into AGENTS.md
    STEALTH_HEADER="> 🔒 **Enterprise / Local-Only Mode Active:**"
    if [ -f "$RESOLVED_TARGET/AGENTS.md" ] && ! grep -Fq "$STEALTH_HEADER" "$RESOLVED_TARGET/AGENTS.md"; then
        TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/agents-stealth.XXXXXX")"
        {
            head -n 2 "$RESOLVED_TARGET/AGENTS.md"
            cat << 'EOF'
> 🔒 **Enterprise / Local-Only Mode Active:**
> This repository utilizes local agent governance without committing agentic files to shared history.
> - **NEVER STAGE OR COMMIT:** `AGENTS.md`, `.agent/`, or any AI workbench files (`git status` MUST ignore them).
> - **Commit Conventions:** Follow organizational standards (e.g. ticket ID prefix `feat(PROJ-123): ...`).
> - **Scope Isolation:** Stage only files directly required for project source code and tests.

EOF
            tail -n +3 "$RESOLVED_TARGET/AGENTS.md"
        } > "$TMP_FILE"
        mv "$TMP_FILE" "$RESOLVED_TARGET/AGENTS.md"
        echo "🔒 Injected Enterprise Stealth Mode directives into AGENTS.md."
    fi
fi

echo ""
echo "======================================================="
if [ "$LOCAL_ONLY" = true ]; then
    echo "🎉 Stealth mode installation completed successfully!"
    echo "🔒 .agent/ and AGENTS.md are ignored via .git/info/exclude."
    echo "⚠️  Your repository git status remains 100% clean."
else
    echo "🎉 Installation completed successfully!"
fi
echo ""
echo "👉 Next steps:"
STEP=1
if [ "$TARGET_DIR" != "." ]; then
    echo "${STEP}. Navigate into your project folder:"
    echo "   cd $TARGET_DIR"
    echo ""
    STEP=$((STEP + 1))
fi
echo "${STEP}. Open in your AI coding environment (Cursor, Windsurf, VS Code, Antigravity):"
echo "   code ."
echo ""
STEP=$((STEP + 1))
echo "${STEP}. Send the initial prompt to the AI agent:"
echo ""
echo "   \"Read AGENTS.md, .agent/TASK.md, and .agent/NOTES.md."
echo "    Present your implementation plan for Task [00.1] Project Discovery and Context Mapping"
echo "    before modifying any code.\""
echo "======================================================="
