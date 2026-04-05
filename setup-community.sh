#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"
ENV_FILE="$SCRIPT_DIR/.env"
PROFILE_FILE=""
PATH_EXPORT_LINE="export PATH=\"$SCRIPT_DIR:\$PATH\""
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
MIGRATIONS_DIR="$SCRIPT_DIR/migrations"

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

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

wait_for_postgres() {
  local attempts=0
  until compose exec -T postgres pg_isready -U groot -d groot >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge 60 ]]; then
      echo "Postgres did not become ready in time." >&2
      exit 1
    fi
    sleep 2
  done
}

run_migrations() {
  if [[ ! -d "$MIGRATIONS_DIR" ]]; then
    echo "Missing migrations directory: $MIGRATIONS_DIR" >&2
    exit 1
  fi

  while IFS= read -r file; do
    compose exec -T postgres psql -U groot -d groot < "$file"
  done < <(find "$MIGRATIONS_DIR" -type f -name '*.sql' | sort)
}

detect_profile_file() {
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    zsh)
      PROFILE_FILE="${ZDOTDIR:-$HOME}/.zshrc"
      ;;
    bash)
      if [[ -f "$HOME/.bashrc" || ! -f "$HOME/.bash_profile" ]]; then
        PROFILE_FILE="$HOME/.bashrc"
      else
        PROFILE_FILE="$HOME/.bash_profile"
      fi
      ;;
    *)
      PROFILE_FILE="$HOME/.profile"
      ;;
  esac
}

ensure_path_install() {
  detect_profile_file

  if [[ ":$PATH:" != *":$SCRIPT_DIR:"* ]]; then
    export PATH="$SCRIPT_DIR:$PATH"
  fi

  mkdir -p "$(dirname "$PROFILE_FILE")"
  touch "$PROFILE_FILE"

  if ! grep -Fqx "$PATH_EXPORT_LINE" "$PROFILE_FILE"; then
    {
      echo
      echo "# Groot Community"
      echo "$PATH_EXPORT_LINE"
    } >>"$PROFILE_FILE"
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

generate_master_key() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 32 | tr -d '\n'
  else
    python3 - <<'PY'
import base64
import secrets
print(base64.b64encode(secrets.token_bytes(32)).decode())
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

explain_public_base_url() {
  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    return
  fi

  cat <<EOF

GROOT_PUBLIC_BASE_URL is the public API URL that external systems use to reach Groot.

Examples:
  - local testing with a reverse tunnel:
      https://abc123.ngrok.app
  - hosted deployment behind a reverse proxy:
      https://groot-api.example.com

This value is used to build the ingest endpoint shown in Settings.
For example:
  GROOT_PUBLIC_BASE_URL=https://groot-api.example.com
  Ingest endpoint: https://groot-api.example.com/events

If your UI and API are on different hosts, use the API host here.

EOF
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

ensure_master_key() {
  local key="$1"
  local placeholder="$2"
  local current
  current="$(get_value "$key")"
  if [[ -z "$current" || "$current" == "$placeholder" ]]; then
    current="$(generate_master_key)"
  fi
  set_value "$key" "$current"
}

require_cmd docker
require_docker_compose
ensure_path_install

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

http_port="$(prompt_value "GROOT_HTTP_PORT" "HTTP port" "8080")"
set_value "GROOT_HTTP_PORT" "$http_port"

ui_port="$(prompt_value "GROOT_UI_PORT" "UI port" "3000")"
set_value "GROOT_UI_PORT" "$ui_port"

explain_public_base_url
base_url="$(prompt_value "GROOT_PUBLIC_BASE_URL" "Public API base URL (used for ingest endpoints)" "http://localhost:${http_port}")"
set_value "GROOT_PUBLIC_BASE_URL" "$base_url"

tenant_name="$(prompt_value "COMMUNITY_TENANT_NAME" "Community tenant name" "Community Tenant")"
set_value "COMMUNITY_TENANT_NAME" "$tenant_name"

api_image="$(prompt_value "GROOT_API_IMAGE" "Groot API image" "groot-community-api:latest")"
set_value "GROOT_API_IMAGE" "$api_image"

ui_image="$(prompt_value "GROOT_UI_IMAGE" "Groot UI image" "groot-community-ui:latest")"
set_value "GROOT_UI_IMAGE" "$ui_image"

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
ensure_master_key "GROOT_SECRETS_MASTER_KEY" "community-secrets-master-key"
ensure_secret "AI_GATEWAY_API_KEY" "groot-ai-gateway-dev-key"
ensure_secret "AI_GATEWAY_STATUS_AUTH_API_KEY" "ai-gateway-status-secret"
ensure_secret "AGENT_RUNTIME_SHARED_SECRET" "agent-runtime-secret"

echo "Starting Postgres for initial schema setup..."
compose up -d postgres
wait_for_postgres

echo "Applying database migrations..."
run_migrations

cat <<EOF

Community bundle configured.

The Groot command has been added to your PATH through:
  $PROFILE_FILE

Next steps:
  1. Open a new terminal, or run:
       source "$PROFILE_FILE"
  2. Start Groot:
       groot start
  3. Open Groot:
       http://localhost:$ui_port
  4. Check status:
       groot status
EOF
