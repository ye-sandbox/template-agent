#!/usr/bin/env bash
# ==============================================================================
# Infra Project Initialization Script (ADD - Services & Homelab)
# Scaffolds a new project from the infra template with a clean Git repository
# ==============================================================================
set -euo pipefail

FORCE_YES=false
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|-f|--force)
            FORCE_YES=true
            shift
            ;;
        -h|--help)
            echo "Usage: init.sh [-y|--yes] [PROJECT_NAME_OR_DIR]"
            echo ""
            echo "Options:"
            echo "  -y, --yes, -f, --force    Run non-interactively without confirmation prompts"
            echo "  -h, --help                Show this help message"
            echo ""
            echo "Example:"
            echo "  curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/infra/init.sh | bash -s -- meu-homelab"
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

# Prompt for directory name if not provided
if [ -z "$TARGET_DIR" ]; then
    if [ -c /dev/tty ]; then
        read -p "Enter folder name for new infra project (e.g. my-homelab): " -r TARGET_DIR </dev/tty || true
    elif [ -t 0 ]; then
        read -p "Enter folder name for new infra project (e.g. my-homelab): " -r TARGET_DIR || true
    fi
fi

if [ -z "$TARGET_DIR" ]; then
    echo "❌ Error: Project directory name was not specified." >&2
    echo "Usage: init.sh [PROJECT_NAME_OR_DIR]" >&2
    exit 1
fi

TEMPLATE_REPO_URL="${TEMPLATE_REPO_URL:-https://github.com/ye-sandbox/template-agent.git}"

echo "======================================================="
echo " Infra Project Scaffolding (ADD Services & Homelab)"
echo " Destination: $(mkdir -p "$TARGET_DIR" && cd "$TARGET_DIR" && pwd)"
echo " Source:      $TEMPLATE_REPO_URL (branch infra)"
echo "======================================================="

# Check if target directory already exists and is non-empty
if [ -d "$TARGET_DIR" ] && [ "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
    echo "⚠️  Warning: Target directory '$TARGET_DIR' already exists and is not empty."
    if [ "$FORCE_YES" != true ]; then
        CONFIRM=""
        if [ -c /dev/tty ]; then
            read -p "Continue anyway? Existing files may be overwritten. (y/N): " -r CONFIRM </dev/tty || true
        elif [ -t 0 ]; then
            read -p "Continue anyway? Existing files may be overwritten. (y/N): " -r CONFIRM || true
        fi
        if [[ ! "$CONFIRM" =~ ^[yYsS]$ ]]; then
            echo "Operation cancelled by user."
            exit 1
        fi
    fi
fi

# Clone template into a temporary directory
TEMP_CLONE_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_CLONE_DIR"' EXIT

echo "⏳ Cloning Infra template..."
git clone --depth 1 -b infra "$TEMPLATE_REPO_URL" "$TEMP_CLONE_DIR" >/dev/null 2>&1

# Copy files to destination
mkdir -p "$TARGET_DIR"
cp -r "$TEMP_CLONE_DIR/." "$TARGET_DIR/"

# Remove initialization script from destination
rm -f "$TARGET_DIR/init.sh"

# Enter destination and initialize fresh Git history
cd "$TARGET_DIR"
rm -rf .git
git init -b main >/dev/null 2>&1

# Configure fallback author if not set globally
GIT_AUTHOR_NAME="$(git config user.name 2>/dev/null || echo "Developer")"
GIT_AUTHOR_EMAIL="$(git config user.email 2>/dev/null || echo "dev@local")"

git add .
GIT_AUTHOR_NAME="$GIT_AUTHOR_NAME" \
GIT_AUTHOR_EMAIL="$GIT_AUTHOR_EMAIL" \
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" \
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL" \
git commit -m "chore: initial infra and service orchestration setup" >/dev/null 2>&1

RESOLVED_PATH="$(pwd)"

echo ""
echo "======================================================="
echo "🎉 Infra project successfully created at:"
echo "   $RESOLVED_PATH"
echo ""
echo "👉 Next steps:"
echo "1. Navigate into your project folder:"
echo "   cd $TARGET_DIR"
echo ""
echo "2. Configure environment variables:"
echo "   cp .env.example .env"
echo ""
echo "3. Create compose.yaml from example:"
echo "   cp compose.yaml.example compose.yaml"
echo ""
echo "4. Open in your AI coding environment (Cursor, Windsurf, VS Code, Antigravity):"
echo "   code ."
echo ""
echo "5. Send the initial prompt to the AI agent:"
echo ""
echo "   \"Read AGENTS.md, .agent/SERVICES.md, .agent/TASK.md, and .agent/skills/compose-service/SKILL.md."
echo "    Present your implementation plan for Task [00.1] before altering configuration files.\""
echo "======================================================="
