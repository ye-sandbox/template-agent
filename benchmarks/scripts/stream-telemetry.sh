#!/usr/bin/env bash
# ==============================================================================
# stream-telemetry.sh — Vector & VictoriaLogs Telemetry Forwarder
# Non-blocking HTTP POST (NDJSON) forwarder to observability collector endpoint (/logs)
# ==============================================================================
set -euo pipefail

# 1. Opt-in guardrail: exit cleanly if telemetry streaming is disabled
if [ "${VECTOR_ENABLED:-false}" != "true" ]; then
    exit 0
fi

METRIC_TYPE="${1:-unknown}"
LEVEL="${2:-info}"
MESSAGE="${3:-Baremetal telemetry event}"
DEFAULT_EXTRA="{}"
EXTRA_JSON="${4:-$DEFAULT_EXTRA}"

VECTOR_HOST="${VECTOR_HOST:-127.0.0.1}"
VECTOR_HTTP_PORT="${VECTOR_HTTP_PORT:-8686}"
SERVICE_NAME="${SERVICE_NAME:-baremetal-workstation}"
ENV="${ENV:-production}"
APP="${APP:-baremetal-tuning}"
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# 2. Construct canonical NDJSON payload
PAYLOAD=""
if command -v python3 >/dev/null 2>&1; then
    PAYLOAD="$(python3 -c '
import sys, json

metric_type = sys.argv[1]
level = sys.argv[2].lower()
message = sys.argv[3]
extra_str = sys.argv[4]
timestamp = sys.argv[5]
service = sys.argv[6]
app = sys.argv[7]
env = sys.argv[8]

base = {
    "timestamp": timestamp,
    "service": service,
    "app": app,
    "env": env,
    "level": level,
    "message": message,
    "metric_type": metric_type
}

try:
    extra = json.loads(extra_str)
    if isinstance(extra, dict):
        base.update(extra)
except Exception:
    pass

print(json.dumps(base, ensure_ascii=False))
' "$METRIC_TYPE" "$LEVEL" "$MESSAGE" "$EXTRA_JSON" "$TIMESTAMP" "$SERVICE_NAME" "$APP" "$ENV" 2>/dev/null || true)"
fi

if [ -z "$PAYLOAD" ]; then
    # Fallback pure shell JSON construction
    EXTRA_CLEAN=""
    if [ "$EXTRA_JSON" != "{}" ] && [ -n "$EXTRA_JSON" ]; then
        EXTRA_CLEAN="$(echo "$EXTRA_JSON" | sed -E 's/^[[:space:]]*\{//; s/\}[[:space:]]*$//')"
        if [ -n "$EXTRA_CLEAN" ]; then
            EXTRA_CLEAN=",$EXTRA_CLEAN"
        fi
    fi
    PAYLOAD="{\"timestamp\":\"$TIMESTAMP\",\"service\":\"$SERVICE_NAME\",\"app\":\"$APP\",\"env\":\"$ENV\",\"level\":\"$LEVEL\",\"message\":\"$MESSAGE\",\"metric_type\":\"$METRIC_TYPE\"$EXTRA_CLEAN}"
fi

# 3. Non-blocking HTTP POST to Vector endpoint
curl -s -X POST "http://${VECTOR_HOST}:${VECTOR_HTTP_PORT}/logs" \
    -H "Content-Type: application/json" \
    --connect-timeout 2 \
    --max-time 4 \
    -d "$PAYLOAD" >/dev/null 2>&1 || true

exit 0
