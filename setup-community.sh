#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"
ENV_FILE="$SCRIPT_DIR/.env"

NON_INTERACTIVE=0
if [[ "${1:-}" == "--non-interactive" ]]; then
  NON_INTERACTIVE=1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_docker_compose() {
  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose is required." >&2
    exit 1
  fi
}

get_value() {
  local key="$1"
  if [[ ! -f "$ENV_FILE" ]]; then
    return 0
  fi
  local line
  line="$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 || true)"
  echo "${line#*=}"
}

set_value() {
  local key="$1"
  local value="$2"
  local tmp
  tmp="$(mktemp)"
  awk -v key="$key" -v value="$value" -F= '
    BEGIN { updated = 0 }
    $1 == key { print key "=" value; updated = 1; next }
    { print }
    END { if (!updated) print key "=" value }
  ' "$ENV_FILE" > "$tmp"
  mv "$tmp" "$ENV_FILE"
}

generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 24
  else
    python3 - <<'PY'
import secrets
print(secrets.token_hex(24))
PY
  fi
}

prompt_value() {
  local key="$1"
  local prompt="$2"
  local default="$3"
  local current
  current="$(get_value "$key")"
  if [[ -z "$current" ]]; then
    current="$default"
  fi

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    echo "$current"
    return
  fi

  local input
  read -r -p "$prompt [$current]: " input
  if [[ -z "$input" ]]; then
    echo "$current"
  else
    echo "$input"
  fi
}

ensure_secret() {
  local key="$1"
  local placeholder="$2"
  local current
  current="$(get_value "$key")"
  if [[ -z "$current" || "$current" == "$placeholder" ]]; then
    current="$(generate_secret)"
  fi
  set_value "$key" "$current"
}

require_cmd docker
require_docker_compose

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

http_port="$(prompt_value "GROOT_HTTP_PORT" "HTTP port" "8080")"
set_value "GROOT_HTTP_PORT" "$http_port"

base_url="$(prompt_value "GROOT_PUBLIC_BASE_URL" "Public base URL" "http://localhost:${http_port}")"
set_value "GROOT_PUBLIC_BASE_URL" "$base_url"

tenant_name="$(prompt_value "COMMUNITY_TENANT_NAME" "Community tenant name" "Community Tenant")"
set_value "COMMUNITY_TENANT_NAME" "$tenant_name"

api_image="$(prompt_value "GROOT_API_IMAGE" "Groot API image" "groot-community-api:latest")"
set_value "GROOT_API_IMAGE" "$api_image"

runtime_image="$(prompt_value "AGENT_RUNTIME_IMAGE" "Agent runtime image" "groot-community-agent-runtime:latest")"
set_value "AGENT_RUNTIME_IMAGE" "$runtime_image"

gateway_image="$(prompt_value "AI_GATEWAY_IMAGE" "AI Gateway image" "groot-community-ai-gateway:latest")"
set_value "AI_GATEWAY_IMAGE" "$gateway_image"

openai_api_key="$(prompt_value "OPENAI_API_KEY" "OpenAI API key (optional)" "$(get_value "OPENAI_API_KEY")")"
set_value "OPENAI_API_KEY" "$openai_api_key"

anthropic_api_key="$(prompt_value "ANTHROPIC_API_KEY" "Anthropic API key (optional)" "$(get_value "ANTHROPIC_API_KEY")")"
set_value "ANTHROPIC_API_KEY" "$anthropic_api_key"

groq_api_key="$(prompt_value "GROQ_API_KEY" "Groq API key (optional)" "$(get_value "GROQ_API_KEY")")"
set_value "GROQ_API_KEY" "$groq_api_key"

hf_token="$(prompt_value "HF_TOKEN" "Hugging Face token (optional)" "$(get_value "HF_TOKEN")")"
set_value "HF_TOKEN" "$hf_token"

ensure_secret "GROOT_SYSTEM_API_KEY" "system-secret"
ensure_secret "AI_GATEWAY_API_KEY" "groot-ai-gateway-dev-key"
ensure_secret "AI_GATEWAY_STATUS_AUTH_API_KEY" "ai-gateway-status-secret"
ensure_secret "AGENT_RUNTIME_SHARED_SECRET" "agent-runtime-secret"

cat <<EOF

Community bundle configured.

Next steps:
  ./groot start
  ./groot migrate
  ./groot status

When mirroring this bundle publicly, replace the default local image names in .env
with the published release image tags for that version.
EOF
