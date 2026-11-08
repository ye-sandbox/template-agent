#!/usr/bin/env bash
# ==============================================================================
# Deterministic LLM Gateway Contract Linter & Pre-Flight Probe Runner
# Statically asserts zero upstream provider coupling in consumer codebases,
# validates canonical environment keys, enforces Docker network boundaries
# (hydra_shared_net vs hydra_ai_net), and executes pre-flight gateway probes.
#
# Usage:
#   verify-llm-contract.sh [command] [options] [target-dir]
#
# Commands:
#   self-test                       Run hermetic end-to-end self-test suite (default if no args)
#   lint [dir] [--json] [--offline] Run static analysis on code, env, and compose files
#   check-code [dir] [--json]       Scan source files for hardcoded upstream models/endpoints
#   check-env <file> [--json]       Validate environment file against canonical LLM schema
#   check-compose <file> [--json]   Validate Docker compose files for network isolation
#   probe [url] [--api-key <k>]     Run pre-flight HTTP probe against LLM gateway
#   -h, --help                      Show help message
#   -v, --version                   Show version information
# ==============================================================================
set -euo pipefail

VERSION="1.0.0"

# ANSI color formatting
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  BOLD="\033[1m"
  GREEN="\033[1;32m"
  RED="\033[1;31m"
  YELLOW="\033[1;33m"
  BLUE="\033[1;34m"
  RESET="\033[0m"
else
  BOLD=""
  GREEN=""
  RED=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

# Temporary cleanup tracker for traps
TMP_CLEANUP_DIRS=()
cleanup_tmp_dirs() {
  for d in "${TMP_CLEANUP_DIRS[@]:-}"; do
    if [ -n "$d" ] && [ -d "$d" ]; then
      rm -rf "$d"
    fi
  done
}
trap cleanup_tmp_dirs EXIT INT TERM

log_info() {
  echo -e "${BLUE}==>${RESET} ${BOLD}$*${RESET}"
}

log_success() {
  echo -e "${GREEN}✓${RESET} $*"
}

log_warn() {
  echo -e "${YELLOW}⚠${RESET} $*" >&2
}

log_error() {
  echo -e "${RED}❌${RESET} $*" >&2
}

show_help() {
  cat << EOF
Deterministic LLM Gateway Contract Linter & Pre-Flight Probe Runner v${VERSION}

Usage:
  $(basename "$0") [command] [options] [target-dir]

Commands:
  self-test
      Execute hermetic end-to-end self-tests verifying code coupling detection,
      environment schema hygiene, compose network boundaries, and probe modes.
      (Default action when invoked without arguments).

  lint [target-dir] [--json] [--offline] [--allow-offline]
      Execute full static analysis on code files, .env.example, and compose files.
      If not offline and LLM_BASE_URL is reachable, optionally runs pre-flight probe.

  check-code [target-dir] [--json]
      Scan source files for hardcoded upstream model strings or provider endpoints.
      Enforces [P1-LLM-UPSTREAM-COUPLING] and [P2-LLM-REASONING-BUDGET].

  check-env <file-path> [--json]
      Validate environment file against canonical schema:
      LLM_BASE_URL, LLM_API_KEY, LLM_MODEL_FAST=fast,
      LLM_MODEL_DEEP=deep, LLM_TIMEOUT_SECONDS >= 180.
      Enforces [P1-LLM-ENV-HYGIENE].

  check-compose <file-path> [--json]
      Validate Docker Compose definitions for network boundaries.
      Prohibits attachment to hydra_ai_net ([P0-LLM-NETWORK-ISOLATION])
      and enforces external: true on hydra_shared_net.

  probe [gateway-base-url] [--api-key <key>] [--json] [--allow-offline] [--timeout <secs>]
      Execute pre-flight HTTP probe against /v1/models and verify virtual models
      (fast, deep) are exposed.

Options:
  --json             Output results formatted as JSON.
  --offline          Skip network calls; perform static audits only.
  --allow-offline    Do not fail if gateway network probe is unreachable.
  --api-key <key>    API token for probe authentication (default: \$LLM_API_KEY or sk-dummy).
  --timeout <secs>   Probe connection timeout in seconds (default: 5).
  -h, --help         Show this help message and exit.
  -v, --version      Show version information and exit.

Invariants & Rules Checked:
  • [P0-LLM-NETWORK-ISOLATION]:
      compose.yaml MUST NOT attach to hydra_ai_net (protects Redis cache and backend).
      External consumer bridge MUST be hydra_shared_net with external: true.
  • [P1-LLM-UPSTREAM-COUPLING]:
      Source code MUST NOT hardcode upstream provider endpoints (generativelanguage.googleapis,
      api.openai.com, api.groq.com) or proprietary model names (gemini-*, gpt-4*, claude-*).
      Must route strictly through virtual model aliases (fast, deep).
  • [P1-LLM-ENV-HYGIENE]:
      Environment manifests MUST declare canonical keys with valid defaults and
      LLM_TIMEOUT_SECONDS >= 180.
  • [P2-LLM-REASONING-BUDGET]:
      Token allocation max_tokens MUST NOT be < 60 to prevent chain-of-thought starvation.
EOF
}

# ------------------------------------------------------------------------------
# Helper: Format JSON Diagnostic Output
# ------------------------------------------------------------------------------
output_json_report() {
  local status="$1"
  local total_violations="$2"
  local violations_json="$3"

  cat << EOF
{
  "scanner": "verify-llm-contract",
  "version": "${VERSION}",
  "status": "${status}",
  "total_violations": ${total_violations},
  "violations": [
${violations_json}
  ]
}
EOF
}

# ------------------------------------------------------------------------------
# Audit Codebase for Upstream Coupling
# ------------------------------------------------------------------------------
check_code_coupling() {
  local TARGET_DIR="${1:-.}"
  local JSON_MODE="${2:-false}"

  if [ ! -d "$TARGET_DIR" ]; then
    log_error "Target directory does not exist: $TARGET_DIR"
    return 2
  fi

  local VIOLATIONS=()
  local VIOLATION_COUNT=0

  # Upstream endpoints pattern
  local ENDPOINT_REGEX="(generativelanguage\.googleapis\.com|api\.openai\.com|api\.groq\.com|api\.anthropic\.com)"
  
  # Upstream model identifiers pattern
  local MODEL_REGEX="(gemini-(1|2|3)\.[0-9]|gemini-(pro|flash|ultra)|gpt-4o|gpt-4-turbo|gpt-4\b|gpt-3\.5|o1-(preview|mini)|o3-mini|claude-(1|2|3)|claude-(instant|haiku|sonnet|opus)|llama-(2|3)\b|llama-3\.[0-9]|deepseek-(r1|v3))"

  # Dangerous low max_tokens (reasoning token starvation)
  local LOW_MAX_TOKENS_REGEX="max_tokens\s*[:=]\s*([1-9]|[1-5][0-9])\b"

  # Find all candidate source files excluding VCS, docs, build caches, and test fixtures
  local SCAN_FILES=()
  while IFS= read -r -d '' file; do
    SCAN_FILES+=("$file")
  done < <(find "$TARGET_DIR" -type f \
    ! -path '*/.git/*' \
    ! -path '*/.github/scripts/*' \
    ! -path '*/node_modules/*' \
    ! -path '*/.venv/*' \
    ! -path '*/venv/*' \
    ! -path '*/vendor/*' \
    ! -path '*/.worktrees/*' \
    ! -path '*/docs/*' \
    ! -path '*/.agent/knowledge/*' \
    ! -name '*.md' \
    ! -name '*.markdown' \
    ! -name '*.lock' \
    ! -name '*.svg' \
    ! -name '*.png' \
    ! -name '*.jpg' \
    ! -name '*.jpeg' \
    ! -name '*.ico' \
    ! -name '*.pdf' \
    ! -name '*.jsonl' \
    ! -name '*.log' \
    -print0)

  for file in "${SCAN_FILES[@]:-}"; do
    [ -f "$file" ] || continue

    # Check for hardcoded upstream endpoints
    local line_no=0
    while IFS= read -r line || [ -n "$line" ]; do
      line_no=$((line_no + 1))
      
      # Skip comment lines
      case "$line" in
        "#"*|"//"*|"/*"*|"* "*) continue ;;
      esac
      
      # Skip lines with explicit ignore directive
      if [[ "$line" =~ allow-upstream-model ]] || [[ "$line" =~ allow-upstream-endpoint ]]; then
        continue
      fi

      # 1. Endpoint Coupling
      if [[ "$line" =~ $ENDPOINT_REGEX ]]; then
        local matched_token="${BASH_REMATCH[1]}"
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
        local rel_path="${file#"$TARGET_DIR"/}"
        VIOLATIONS+=("{\"rule\":\"P1-LLM-UPSTREAM-COUPLING\",\"file\":\"${rel_path}\",\"line\":${line_no},\"token\":\"${matched_token}\",\"message\":\"Hardcoded upstream provider endpoint detected. Consumer applications must route via LLM_BASE_URL (Hydra AI gateway).\"}")
        if [ "$JSON_MODE" != "true" ]; then
          log_error "[P1-LLM-UPSTREAM-COUPLING] ${rel_path}:${line_no} -> Hardcoded upstream endpoint '${matched_token}'"
        fi
      fi

      # 2. Model String Coupling
      if [[ "$line" =~ $MODEL_REGEX ]]; then
        local matched_model="${BASH_REMATCH[1]}"
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
        local rel_path="${file#"$TARGET_DIR"/}"
        VIOLATIONS+=("{\"rule\":\"P1-LLM-UPSTREAM-COUPLING\",\"file\":\"${rel_path}\",\"line\":${line_no},\"token\":\"${matched_model}\",\"message\":\"Hardcoded upstream proprietary model identifier detected. Consumer applications must use virtual model aliases (fast, deep).\"}")
        if [ "$JSON_MODE" != "true" ]; then
          log_error "[P1-LLM-UPSTREAM-COUPLING] ${rel_path}:${line_no} -> Hardcoded proprietary model '${matched_model}'"
        fi
      fi

      # 3. Reasoning Token Headroom Starvation
      if [[ "$line" =~ $LOW_MAX_TOKENS_REGEX ]]; then
        local matched_val="${BASH_REMATCH[1]}"
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
        local rel_path="${file#"$TARGET_DIR"/}"
        VIOLATIONS+=("{\"rule\":\"P2-LLM-REASONING-BUDGET\",\"file\":\"${rel_path}\",\"line\":${line_no},\"token\":\"max_tokens=${matched_val}\",\"message\":\"Low max_tokens (< 60) detected. Chain-of-thought models (e.g. Gemini thinking) consume reasoning tokens first and will return empty content.\"}")
        if [ "$JSON_MODE" != "true" ]; then
          log_warn "[P2-LLM-REASONING-BUDGET] ${rel_path}:${line_no} -> Low max_tokens=${matched_val} (< 60) risks reasoning token starvation"
        fi
      fi

    done < "$file"
  done

  if [ "$JSON_MODE" = "true" ]; then
    local joined_violations=""
    for ((i=0; i<${#VIOLATIONS[@]}; i++)); do
      joined_violations+="${VIOLATIONS[i]}"
      if [ $i -lt $((${#VIOLATIONS[@]} - 1)) ]; then
        joined_violations+=","
      fi
    done
    local status="PASS"
    [ $VIOLATION_COUNT -gt 0 ] && status="FAIL"
    output_json_report "$status" "$VIOLATION_COUNT" "$joined_violations"
  fi

  if [ $VIOLATION_COUNT -eq 0 ]; then
    [ "$JSON_MODE" != "true" ] && log_success "Zero upstream provider coupling verified (${#SCAN_FILES[@]} source files clean)."
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Validate Environment Manifest (.env.example / .env)
# ------------------------------------------------------------------------------
check_env_hygiene() {
  local ENV_FILE="$1"
  local JSON_MODE="${2:-false}"

  if [ ! -f "$ENV_FILE" ]; then
    log_error "Environment file not found: $ENV_FILE"
    return 2
  fi

  local VIOLATIONS=()
  local VIOLATION_COUNT=0

  local HAS_BASE_URL="false"
  local HAS_API_KEY="false"
  local HAS_MODEL_FAST="false"
  local HAS_MODEL_DEEP="false"
  local HAS_TIMEOUT="false"

  local BASE_URL_VAL=""
  local MODEL_FAST_VAL=""
  local MODEL_DEEP_VAL=""
  local TIMEOUT_VAL=""

  local line_no=0
  while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    line_no=$((line_no + 1))
    # Strip carriage returns and leading/trailing whitespace
    local line
    line="$(echo "$raw_line" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Ignore comments and blanks
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    if [[ "$line" =~ ^LLM_BASE_URL=(.*)$ ]]; then
      HAS_BASE_URL="true"
      BASE_URL_VAL="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^LLM_API_KEY=(.*)$ ]]; then
      HAS_API_KEY="true"
    elif [[ "$line" =~ ^LLM_MODEL_FAST=(.*)$ ]]; then
      HAS_MODEL_FAST="true"
      MODEL_FAST_VAL="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^LLM_MODEL_DEEP=(.*)$ ]]; then
      HAS_MODEL_DEEP="true"
      MODEL_DEEP_VAL="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^LLM_TIMEOUT_SECONDS=(.*)$ ]]; then
      HAS_TIMEOUT="true"
      TIMEOUT_VAL="${BASH_REMATCH[1]}"
    fi
  done < "$ENV_FILE"

  # 1. Assert Key Existence
  if [ "$HAS_BASE_URL" != "true" ]; then
    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_BASE_URL\",\"message\":\"Missing required environment variable LLM_BASE_URL\"}")
    [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: Missing required variable 'LLM_BASE_URL'"
  fi

  if [ "$HAS_API_KEY" != "true" ]; then
    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_API_KEY\",\"message\":\"Missing required environment variable LLM_API_KEY\"}")
    [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: Missing required variable 'LLM_API_KEY'"
  fi

  if [ "$HAS_MODEL_FAST" != "true" ]; then
    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_MODEL_FAST\",\"message\":\"Missing required environment variable LLM_MODEL_FAST\"}")
    [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: Missing required variable 'LLM_MODEL_FAST'"
  fi

  if [ "$HAS_MODEL_DEEP" != "true" ]; then
    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_MODEL_DEEP\",\"message\":\"Missing required environment variable LLM_MODEL_DEEP\"}")
    [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: Missing required variable 'LLM_MODEL_DEEP'"
  fi

  if [ "$HAS_TIMEOUT" != "true" ]; then
    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_TIMEOUT_SECONDS\",\"message\":\"Missing required environment variable LLM_TIMEOUT_SECONDS\"}")
    [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: Missing required variable 'LLM_TIMEOUT_SECONDS'"
  fi

  # 2. Value Schema Assertions
  if [ "$HAS_BASE_URL" = "true" ]; then
    # Must be valid URL protocol
    if ! [[ "$BASE_URL_VAL" =~ ^https?:// ]]; then
      VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_BASE_URL\",\"message\":\"Invalid LLM_BASE_URL format '${BASE_URL_VAL}'. Must start with http:// or https://.\"}")
      [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: Invalid LLM_BASE_URL '${BASE_URL_VAL}'"
    fi
  fi

  if [ "$HAS_MODEL_FAST" = "true" ]; then
    if [ "$MODEL_FAST_VAL" != "fast" ]; then
      VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_MODEL_FAST\",\"message\":\"LLM_MODEL_FAST must be set to canonical virtual alias 'fast', got '${MODEL_FAST_VAL}'\"}")
      [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: LLM_MODEL_FAST must be 'fast', got '${MODEL_FAST_VAL}'"
    fi
  fi

  if [ "$HAS_MODEL_DEEP" = "true" ]; then
    if [ "$MODEL_DEEP_VAL" != "deep" ]; then
      VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_MODEL_DEEP\",\"message\":\"LLM_MODEL_DEEP must be set to canonical virtual alias 'deep', got '${MODEL_DEEP_VAL}'\"}")
      [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: LLM_MODEL_DEEP must be 'deep', got '${MODEL_DEEP_VAL}'"
    fi
  fi

  if [ "$HAS_TIMEOUT" = "true" ]; then
    # Strip inline comments or quotes
    TIMEOUT_VAL="$(echo "$TIMEOUT_VAL" | sed -e 's/[[:space:]]*#.*$//' -e 's/["'\'']//g')"
    if ! [[ "$TIMEOUT_VAL" =~ ^[0-9]+$ ]] || [ "$TIMEOUT_VAL" -lt 180 ]; then
      VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      VIOLATIONS+=("{\"rule\":\"P1-LLM-ENV-HYGIENE\",\"file\":\"${ENV_FILE}\",\"key\":\"LLM_TIMEOUT_SECONDS\",\"message\":\"LLM_TIMEOUT_SECONDS must be an integer >= 180 to accommodate deep reasoning budgets, got '${TIMEOUT_VAL}'\"}")
      [ "$JSON_MODE" != "true" ] && log_error "[P1-LLM-ENV-HYGIENE] ${ENV_FILE}: LLM_TIMEOUT_SECONDS must be >= 180, got '${TIMEOUT_VAL}'"
    fi
  fi

  if [ "$JSON_MODE" = "true" ]; then
    local joined_violations=""
    for ((i=0; i<${#VIOLATIONS[@]}; i++)); do
      joined_violations+="${VIOLATIONS[i]}"
      if [ $i -lt $((${#VIOLATIONS[@]} - 1)) ]; then
        joined_violations+=","
      fi
    done
    local status="PASS"
    [ $VIOLATION_COUNT -gt 0 ] && status="FAIL"
    output_json_report "$status" "$VIOLATION_COUNT" "$joined_violations"
  fi

  if [ $VIOLATION_COUNT -eq 0 ]; then
    [ "$JSON_MODE" != "true" ] && log_success "Environment schema verified in ${ENV_FILE}."
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Validate Docker Compose Network Isolation
# ------------------------------------------------------------------------------
check_compose_hygiene() {
  local COMPOSE_FILE="$1"
  local JSON_MODE="${2:-false}"

  if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Compose file not found: $COMPOSE_FILE"
    return 2
  fi

  local VIOLATIONS=()
  local VIOLATION_COUNT=0

  # 1. P0 Check: Prohibited network hydra_ai_net
  if grep -qE "hydra_ai_net" "$COMPOSE_FILE"; then
    local line_no
    line_no="$(grep -nE "hydra_ai_net" "$COMPOSE_FILE" | head -n 1 | cut -d: -f1)"
    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    VIOLATIONS+=("{\"rule\":\"P0-LLM-NETWORK-ISOLATION\",\"file\":\"${COMPOSE_FILE}\",\"line\":${line_no},\"token\":\"hydra_ai_net\",\"message\":\"CRITICAL SECURITY VIOLATION: Consumer services MUST NOT attach to internal network 'hydra_ai_net' (exposes internal Redis/database). Use 'hydra_shared_net' instead.\"}")
    if [ "$JSON_MODE" != "true" ]; then
      log_error "[P0-LLM-NETWORK-ISOLATION] ${COMPOSE_FILE}:${line_no} -> Prohibited internal network 'hydra_ai_net' detected!"
    fi
  fi

  # 2. Check if LLM gateway container or network is referenced
  if grep -qE "(hydra-ai-gateway|hydra_shared_net|LLM_BASE_URL)" "$COMPOSE_FILE"; then
    # Must declare hydra_shared_net as external: true
    if ! grep -qE "hydra_shared_net" "$COMPOSE_FILE"; then
      VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      VIOLATIONS+=("{\"rule\":\"P0-LLM-NETWORK-ISOLATION\",\"file\":\"${COMPOSE_FILE}\",\"message\":\"Compose file references LLM gateway but does not attach services to 'hydra_shared_net'.\"}")
      if [ "$JSON_MODE" != "true" ]; then
        log_error "[P0-LLM-NETWORK-ISOLATION] ${COMPOSE_FILE}: Missing 'hydra_shared_net' network attachment"
      fi
    elif ! grep -A 4 -E "hydra_shared_net:" "$COMPOSE_FILE" | grep -v '^[[:space:]]*#' | grep -qE "^[[:space:]]*external:[[:space:]]*true"; then
      VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
      VIOLATIONS+=("{\"rule\":\"P0-LLM-NETWORK-ISOLATION\",\"file\":\"${COMPOSE_FILE}\",\"message\":\"Network 'hydra_shared_net' must be declared with 'external: true'.\"}")
      if [ "$JSON_MODE" != "true" ]; then
        log_error "[P0-LLM-NETWORK-ISOLATION] ${COMPOSE_FILE}: 'hydra_shared_net' must declare 'external: true'"
      fi
    fi
  fi

  if [ "$JSON_MODE" = "true" ]; then
    local joined_violations=""
    for ((i=0; i<${#VIOLATIONS[@]}; i++)); do
      joined_violations+="${VIOLATIONS[i]}"
      if [ $i -lt $((${#VIOLATIONS[@]} - 1)) ]; then
        joined_violations+=","
      fi
    done
    local status="PASS"
    [ $VIOLATION_COUNT -gt 0 ] && status="FAIL"
    output_json_report "$status" "$VIOLATION_COUNT" "$joined_violations"
  fi

  if [ $VIOLATION_COUNT -eq 0 ]; then
    [ "$JSON_MODE" != "true" ] && log_success "Compose network isolation verified in ${COMPOSE_FILE}."
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Pre-Flight Gateway Probe Runner
# ------------------------------------------------------------------------------
run_probe() {
  local BASE_URL="${1:-}"
  local API_KEY="${2:-${LLM_API_KEY:-sk-dummy-token}}"
  local JSON_MODE="${3:-false}"
  local ALLOW_OFFLINE="${4:-false}"
  local TIMEOUT="${5:-5}"

  if [ -z "$BASE_URL" ]; then
    BASE_URL="${LLM_BASE_URL:-http://127.0.0.1:3000/v1}"
  fi

  # Normalize base URL (strip trailing slash)
  BASE_URL="${BASE_URL%/}"
  local MODELS_URL="${BASE_URL}/models"
  # If base URL doesn't contain /v1, and /models returned 404, check /v1/models
  if [[ "$BASE_URL" != */v1 ]]; then
    MODELS_URL="${BASE_URL}/v1/models"
  fi

  [ "$JSON_MODE" != "true" ] && log_info "Probing LLM gateway models at: ${MODELS_URL} (timeout: ${TIMEOUT}s)..."

  # Perform curl probe
  local HTTP_RESP=""
  local HTTP_CODE="000"
  local CURL_OUT=""

  CURL_OUT="$(curl -sS -m "$TIMEOUT" -w "\n%{http_code}" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Accept: application/json" \
    "${MODELS_URL}" 2>&1)" || {
      local curl_err=$?
      if [ "$ALLOW_OFFLINE" = "true" ]; then
        [ "$JSON_MODE" != "true" ] && log_warn "Gateway probe unreachable (offline allowed, code: ${curl_err}). Skipping probe."
        if [ "$JSON_MODE" = "true" ]; then
          cat << EOF
{
  "scanner": "verify-llm-contract",
  "version": "${VERSION}",
  "probe": {
    "target_url": "${MODELS_URL}",
    "status": "SKIPPED",
    "reason": "Host unreachable; allow_offline enabled"
  }
}
EOF
        fi
        return 0
      else
        [ "$JSON_MODE" != "true" ] && log_error "Failed to connect to gateway at ${MODELS_URL} (curl error: ${curl_err})"
        if [ "$JSON_MODE" = "true" ]; then
          cat << EOF
{
  "scanner": "verify-llm-contract",
  "version": "${VERSION}",
  "probe": {
    "target_url": "${MODELS_URL}",
    "status": "ERROR",
    "curl_code": ${curl_err}
  }
}
EOF
        fi
        return 1
      fi
    }

  # Parse response body and HTTP code
  HTTP_CODE="$(echo "$CURL_OUT" | tail -n 1)"
  HTTP_RESP="$(echo "$CURL_OUT" | sed '$d')"

  if [ "$HTTP_CODE" != "200" ]; then
    [ "$JSON_MODE" != "true" ] && log_error "Gateway probe returned unexpected HTTP status ${HTTP_CODE}: ${HTTP_RESP}"
    if [ "$JSON_MODE" = "true" ]; then
      cat << EOF
{
  "scanner": "verify-llm-contract",
  "version": "${VERSION}",
  "probe": {
    "target_url": "${MODELS_URL}",
    "status": "FAIL",
    "http_code": ${HTTP_CODE}
  }
}
EOF
    fi
    return 1
  fi

  # Verify virtual model aliases are present in the response
  local HAS_FAST="false"
  local HAS_DEEP="false"
  if echo "$HTTP_RESP" | grep -q "fast"; then
    HAS_FAST="true"
  fi
  if echo "$HTTP_RESP" | grep -q "deep"; then
    HAS_DEEP="true"
  fi

  if [ "$HAS_FAST" = "true" ] && [ "$HAS_DEEP" = "true" ]; then
    [ "$JSON_MODE" != "true" ] && log_success "Gateway probe verified: virtual models 'fast' and 'deep' are active."
    if [ "$JSON_MODE" = "true" ]; then
      cat << EOF
{
  "scanner": "verify-llm-contract",
  "version": "${VERSION}",
  "probe": {
    "target_url": "${MODELS_URL}",
    "status": "PASS",
    "models": ["fast", "deep"]
  }
}
EOF
    fi
    return 0
  else
    [ "$JSON_MODE" != "true" ] && log_error "Gateway probe missing required virtual models. fast: ${HAS_FAST}, deep: ${HAS_DEEP}"
    if [ "$JSON_MODE" = "true" ]; then
      cat << EOF
{
  "scanner": "verify-llm-contract",
  "version": "${VERSION}",
  "probe": {
    "target_url": "${MODELS_URL}",
    "status": "FAIL",
    "free_fast": ${HAS_FAST},
    "free_deep": ${HAS_DEEP}
  }
}
EOF
    fi
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Full Workspace Linter
# ------------------------------------------------------------------------------
run_lint() {
  local TARGET_DIR="${1:-.}"
  local JSON_MODE="${2:-false}"
  local OFFLINE_MODE="${3:-false}"
  local ALLOW_OFFLINE="${4:-false}"

  [ "$JSON_MODE" != "true" ] && log_info "Executing LLM Gateway Contract Linter on ${TARGET_DIR}..."

  local EXIT_CODE=0

  # 1. Code coupling scan
  [ "$JSON_MODE" != "true" ] && log_info "Step 1/3: Scanning source files for upstream provider coupling..."
  if ! check_code_coupling "$TARGET_DIR" "$JSON_MODE"; then
    EXIT_CODE=1
  fi

  # 2. Environment manifests
  [ "$JSON_MODE" != "true" ] && log_info "Step 2/3: Auditing environment manifests..."
  local ENV_FILES_FOUND=0
  for env_cand in "${TARGET_DIR}/.env.example" "${TARGET_DIR}/.env"; do
    if [ -f "$env_cand" ]; then
      ENV_FILES_FOUND=$((ENV_FILES_FOUND + 1))
      if ! check_env_hygiene "$env_cand" "$JSON_MODE"; then
        EXIT_CODE=1
      fi
    fi
  done
  if [ $ENV_FILES_FOUND -eq 0 ] && [ "$JSON_MODE" != "true" ]; then
    log_warn "No .env.example or .env file found in ${TARGET_DIR}."
  fi

  # 3. Docker compose network boundaries
  [ "$JSON_MODE" != "true" ] && log_info "Step 3/3: Auditing Docker Compose network isolation..."
  for compose_cand in "${TARGET_DIR}/compose.yaml" "${TARGET_DIR}/compose.yml" "${TARGET_DIR}/docker-compose.yml" "${TARGET_DIR}/compose.yaml.example"; do
    if [ -f "$compose_cand" ]; then
      if ! check_compose_hygiene "$compose_cand" "$JSON_MODE"; then
        EXIT_CODE=1
      fi
    fi
  done

  # 4. Optional online probe if not offline
  if [ "$OFFLINE_MODE" != "true" ] && [ -n "${LLM_BASE_URL:-}" ]; then
    [ "$JSON_MODE" != "true" ] && log_info "Optional: Executing online pre-flight probe..."
    if ! run_probe "${LLM_BASE_URL}" "${LLM_API_KEY:-}" "$JSON_MODE" "$ALLOW_OFFLINE"; then
      EXIT_CODE=1
    fi
  fi

  if [ $EXIT_CODE -eq 0 ]; then
    [ "$JSON_MODE" != "true" ] && log_success "All LLM Gateway contracts and guardrails PASSED for ${TARGET_DIR}."
  else
    [ "$JSON_MODE" != "true" ] && log_error "LLM Gateway contract verification FAILED for ${TARGET_DIR}."
  fi

  return $EXIT_CODE
}

# ------------------------------------------------------------------------------
# Hermetic Self-Tests Suite
# ------------------------------------------------------------------------------
run_self_tests() {
  log_info "Executing Hermetic Self-Test Suite for verify-llm-contract.sh v${VERSION}..."

  local TEST_TMP
  TEST_TMP="$(mktemp -d -t llm-contract-selftest-XXXXXX)"
  TMP_CLEANUP_DIRS+=("$TEST_TMP")

  local SUITE_FAILURES=0

  # ----------------------------------------------------------------------------
  # Self-Test 1: Clean Compliant Repository Fixture
  # ----------------------------------------------------------------------------
  log_info "Self-Test 1: Clean Compliant Repository Fixture..."
  local DIR_CLEAN="${TEST_TMP}/clean-repo"
  mkdir -p "${DIR_CLEAN}/src"

  cat << 'EOF' > "${DIR_CLEAN}/.env.example"
LLM_BASE_URL=http://hydra-llm-router:3000/v1
LLM_API_KEY=sk-test-token
LLM_MODEL_FAST=fast
LLM_MODEL_DEEP=deep
LLM_TIMEOUT_SECONDS=180
EOF

  cat << 'EOF' > "${DIR_CLEAN}/src/client.py"
import os
from openai import AsyncOpenAI

client = AsyncOpenAI(
    base_url=os.getenv("LLM_BASE_URL", "http://hydra-llm-router:3000/v1"),
    api_key=os.environ["LLM_API_KEY"],
    timeout=float(os.getenv("LLM_TIMEOUT_SECONDS", "180.0")),
)

async def ask():
    return await client.chat.completions.create(
        model=os.getenv("LLM_MODEL_FAST", "free-fast"),
        messages=[{"role": "user", "content": "ping"}],
        max_tokens=100,
    )
EOF

  cat << 'EOF' > "${DIR_CLEAN}/compose.yaml"
services:
  app:
    image: test:1.0
    networks:
      - default
      - hydra_shared_net
networks:
  default:
  hydra_shared_net:
    name: hydra_shared_net
    external: true
EOF

  if check_code_coupling "${DIR_CLEAN}" "false" && \
     check_env_hygiene "${DIR_CLEAN}/.env.example" "false" && \
     check_compose_hygiene "${DIR_CLEAN}/compose.yaml" "false"; then
    log_success "Self-Test 1 passed: Compliant fixture successfully validated."
  else
    log_error "Self-Test 1 failed: Compliant fixture threw unexpected error."
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  fi

  # ----------------------------------------------------------------------------
  # Self-Test 2: Upstream Model String & Endpoint Coupling Detection
  # ----------------------------------------------------------------------------
  log_info "Self-Test 2: Upstream Model String & Endpoint Detection..."
  local DIR_BAD_CODE="${TEST_TMP}/bad-code"
  mkdir -p "${DIR_BAD_CODE}/src"

  cat << 'EOF' > "${DIR_BAD_CODE}/src/service.ts"
import OpenAI from "openai";
// Violation 1: Upstream endpoint
const client = new OpenAI({ baseURL: "https://generativelanguage.googleapis.com/v1beta/openai" });

// Violation 2: Hardcoded proprietary model
export async function run() {
  return await client.chat.completions.create({
    model: "gemini-2.5-flash",
    messages: [{ role: "user", content: "test" }]
  });
}

// Violation 3: Hardcoded gpt-4o model
export async function run2() {
  return await client.chat.completions.create({
    model: "gpt-4o",
    messages: []
  });
}
EOF

  if check_code_coupling "${DIR_BAD_CODE}" "false" >/dev/null 2>&1; then
    log_error "Self-Test 2 failed: Bad code coupling was not detected!"
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  else
    log_success "Self-Test 2 passed: Upstream model strings and endpoints caught."
  fi

  # ----------------------------------------------------------------------------
  # Self-Test 3: Low max_tokens Warning/Violation (< 60)
  # ----------------------------------------------------------------------------
  log_info "Self-Test 3: Low max_tokens (< 60) Detection..."
  local DIR_BAD_TOKENS="${TEST_TMP}/bad-tokens"
  mkdir -p "${DIR_BAD_TOKENS}/src"

  cat << 'EOF' > "${DIR_BAD_TOKENS}/src/probe.py"
response = client.chat.completions.create(
    model="free-deep",
    max_tokens=5, # Starves thinking models!
)
EOF

  if check_code_coupling "${DIR_BAD_TOKENS}" "false" >/dev/null 2>&1; then
    log_error "Self-Test 3 failed: Low max_tokens violation was not detected!"
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  else
    log_success "Self-Test 3 passed: Low max_tokens reasoning budget violation caught."
  fi

  # ----------------------------------------------------------------------------
  # Self-Test 4: Environment Schema Failures (Missing & Invalid Keys)
  # ----------------------------------------------------------------------------
  log_info "Self-Test 4: Environment Schema Failures..."
  local DIR_BAD_ENV="${TEST_TMP}/bad-env"
  mkdir -p "${DIR_BAD_ENV}"

  # Bad 4a: Missing LLM_MODEL_FAST
  cat << 'EOF' > "${DIR_BAD_ENV}/env_missing.env"
LLM_BASE_URL=http://hydra-llm-router:3000/v1
LLM_API_KEY=test
LLM_MODEL_DEEP=deep
LLM_TIMEOUT_SECONDS=180
EOF

  # Bad 4b: Invalid virtual model value
  cat << 'EOF' > "${DIR_BAD_ENV}/env_bad_model.env"
LLM_BASE_URL=http://hydra-llm-router:3000/v1
LLM_API_KEY=test
LLM_MODEL_FAST=gpt-4o
LLM_MODEL_DEEP=deep
LLM_TIMEOUT_SECONDS=180
EOF

  # Bad 4c: Insufficient timeout (< 180)
  cat << 'EOF' > "${DIR_BAD_ENV}/env_bad_timeout.env"
LLM_BASE_URL=http://hydra-llm-router:3000/v1
LLM_API_KEY=test
LLM_MODEL_FAST=fast
LLM_MODEL_DEEP=deep
LLM_TIMEOUT_SECONDS=30
EOF

  local env_checks_passed=0
  check_env_hygiene "${DIR_BAD_ENV}/env_missing.env" "false" >/dev/null 2>&1 || env_checks_passed=$((env_checks_passed + 1))
  check_env_hygiene "${DIR_BAD_ENV}/env_bad_model.env" "false" >/dev/null 2>&1 || env_checks_passed=$((env_checks_passed + 1))
  check_env_hygiene "${DIR_BAD_ENV}/env_bad_timeout.env" "false" >/dev/null 2>&1 || env_checks_passed=$((env_checks_passed + 1))

  if [ $env_checks_passed -eq 3 ]; then
    log_success "Self-Test 4 passed: All environment schema violations correctly caught."
  else
    log_error "Self-Test 4 failed: Expected 3 env failures, got ${env_checks_passed}."
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  fi

  # ----------------------------------------------------------------------------
  # Self-Test 5: Compose Isolation Breach (hydra_ai_net Prohibited)
  # ----------------------------------------------------------------------------
  log_info "Self-Test 5: Compose Network Isolation (hydra_ai_net P0 Violation)..."
  local DIR_BAD_COMPOSE="${TEST_TMP}/bad-compose"
  mkdir -p "${DIR_BAD_COMPOSE}"

  cat << 'EOF' > "${DIR_BAD_COMPOSE}/compose.yaml"
services:
  app:
    image: my-service:latest
    networks:
      - hydra_ai_net # CRITICAL SECURITY RISK
EOF

  if check_compose_hygiene "${DIR_BAD_COMPOSE}/compose.yaml" "false" >/dev/null 2>&1; then
    log_error "Self-Test 5 failed: Prohibited hydra_ai_net network was not flagged!"
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  else
    log_success "Self-Test 5 passed: hydra_ai_net attachment strictly rejected."
  fi

  # ----------------------------------------------------------------------------
  # Self-Test 6: Compose Network Missing external: true
  # ----------------------------------------------------------------------------
  log_info "Self-Test 6: Compose hydra_shared_net Missing external: true..."
  cat << 'EOF' > "${DIR_BAD_COMPOSE}/compose_no_external.yaml"
services:
  app:
    image: my-service:latest
    networks:
      - hydra_shared_net
networks:
  hydra_shared_net:
    driver: bridge # Internal bridge used instead of external: true
EOF

  if check_compose_hygiene "${DIR_BAD_COMPOSE}/compose_no_external.yaml" "false" >/dev/null 2>&1; then
    log_error "Self-Test 6 failed: Missing external: true on hydra_shared_net was not flagged!"
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  else
    log_success "Self-Test 6 passed: Non-external hydra_shared_net correctly flagged."
  fi

  # ----------------------------------------------------------------------------
  # Self-Test 7: Mock HTTP Probe Simulation (Local Mock Server)
  # ----------------------------------------------------------------------------
  log_info "Self-Test 7: Pre-Flight Probe Runner via Local Mock Server..."
  local MOCK_PORT=39123
  local MOCK_PID=""

  # Launch a minimal mock HTTP server via Python
  python3 -c "
import http.server
import socketserver
import json

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ('/models', '/v1/models'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            payload = {
                'object': 'list',
                'data': [
                    {'id': 'fast', 'object': 'model'},
                    {'id': 'deep', 'object': 'model'}
                ]
            }
            self.wfile.write(json.dumps(payload).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, format, *args):
        pass

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('127.0.0.1', ${MOCK_PORT}), Handler) as httpd:
    httpd.serve_forever()
" &
  MOCK_PID=$!
  sleep 0.5

  local probe_result=0
  run_probe "http://127.0.0.1:${MOCK_PORT}/v1" "sk-test" "false" "false" 2 || probe_result=1

  # Terminate mock server
  if [ -n "$MOCK_PID" ] && kill -0 "$MOCK_PID" 2>/dev/null; then
    kill "$MOCK_PID" 2>/dev/null || true
    wait "$MOCK_PID" 2>/dev/null || true
  fi

  if [ $probe_result -eq 0 ]; then
    log_success "Self-Test 7 passed: Mock HTTP probe verified virtual model resolution."
  else
    log_error "Self-Test 7 failed: Mock HTTP probe did not succeed."
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  fi

  # ----------------------------------------------------------------------------
  # Self-Test 8: Probe Offline Graceful Degradation (--allow-offline)
  # ----------------------------------------------------------------------------
  log_info "Self-Test 8: Probe Offline Graceful Degradation..."
  # Target an unreachable port with --allow-offline
  if run_probe "http://127.0.0.1:39999/v1" "sk-test" "false" "true" 1; then
    log_success "Self-Test 8 passed: Offline graceful skip verified."
  else
    log_error "Self-Test 8 failed: Offline graceful skip did not exit 0."
    SUITE_FAILURES=$((SUITE_FAILURES + 1))
  fi

  # ----------------------------------------------------------------------------
  # Self-Test Summary
  # ----------------------------------------------------------------------------
  if [ $SUITE_FAILURES -eq 0 ]; then
    log_success "All 8 self-tests PASSED successfully!"
    return 0
  else
    log_error "${SUITE_FAILURES} self-test(s) failed."
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Main Entrypoint
# ------------------------------------------------------------------------------
main() {
  local COMMAND=""
  local TARGET=""
  local JSON_MODE="false"
  local OFFLINE_MODE="false"
  local ALLOW_OFFLINE="false"
  local API_KEY=""
  local TIMEOUT="5"

  while [ $# -gt 0 ]; do
    case "$1" in
      self-test|lint|check-code|check-env|check-compose|probe)
        COMMAND="$1"
        shift
        ;;
      --json)
        JSON_MODE="true"
        shift
        ;;
      --offline)
        OFFLINE_MODE="true"
        shift
        ;;
      --allow-offline)
        ALLOW_OFFLINE="true"
        shift
        ;;
      --api-key)
        [ $# -ge 2 ] || { log_error "Missing value for --api-key"; exit 2; }
        API_KEY="$2"
        shift 2
        ;;
      --timeout)
        [ $# -ge 2 ] || { log_error "Missing value for --timeout"; exit 2; }
        TIMEOUT="$2"
        shift 2
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -v|--version)
        echo "verify-llm-contract.sh v${VERSION}"
        exit 0
        ;;
      *)
        if [ -z "$TARGET" ]; then
          TARGET="$1"
          shift
        else
          log_error "Unknown argument: $1"
          show_help
          exit 2
        fi
        ;;
    esac
  done

  # Default action: self-test
  if [ -z "$COMMAND" ]; then
    COMMAND="self-test"
  fi

  case "$COMMAND" in
    self-test)
      run_self_tests
      ;;
    lint)
      run_lint "${TARGET:-.}" "$JSON_MODE" "$OFFLINE_MODE" "$ALLOW_OFFLINE"
      ;;
    check-code)
      check_code_coupling "${TARGET:-.}" "$JSON_MODE"
      ;;
    check-env)
      [ -n "$TARGET" ] || { log_error "Usage: $(basename "$0") check-env <file>"; exit 2; }
      check_env_hygiene "$TARGET" "$JSON_MODE"
      ;;
    check-compose)
      [ -n "$TARGET" ] || { log_error "Usage: $(basename "$0") check-compose <file>"; exit 2; }
      check_compose_hygiene "$TARGET" "$JSON_MODE"
      ;;
    probe)
      run_probe "${TARGET:-}" "${API_KEY:-${LLM_API_KEY:-}}" "$JSON_MODE" "$ALLOW_OFFLINE" "$TIMEOUT"
      ;;
  esac
}

main "$@"
