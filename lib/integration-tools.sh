#!/usr/bin/env bash

normalize_integration_name() {
  local raw_name="$1"
  local normalized
  normalized="$(printf '%s' "$raw_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//; s/__+/_/g')"
  if [[ -z "$normalized" ]]; then
    echo "Integration name must contain at least one letter or number." >&2
    exit 1
  fi
  echo "$normalized"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required for Community plugin builds and verification." >&2
    exit 1
  fi
}

display_name_for_integration() {
  local name="$1"
  python3 - <<'PY' "$name"
import sys

name = sys.argv[1]
parts = [part for part in name.replace("-", "_").split("_") if part]
print(" ".join(part.capitalize() for part in parts) or "Integration")
PY
}

struct_name_for_integration() {
  local name="$1"
  python3 - <<'PY' "$name"
import sys

name = sys.argv[1]
parts = [part for part in name.replace("-", "_").split("_") if part]
camel = "".join(part.capitalize() for part in parts) or "Integration"
if camel[0].isdigit():
    camel = "X" + camel
print(camel + "Integration")
PY
}

module_path_for_repo() {
  local target_dir="$1"
  local repo_name
  repo_name="$(basename "$target_dir")"
  repo_name="$(printf '%s' "$repo_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//')"
  if [[ -z "$repo_name" ]]; then
    repo_name="groot-plugin"
  fi
  echo "example.com/${repo_name}"
}

validate_community_root() {
  local candidate="$1"
  [[ -n "$candidate" ]] || return 1
  [[ -f "$candidate/docker-compose.yml" ]] || return 1
  [[ -x "$candidate/groot" ]] || return 1
  [[ -d "$candidate/integrations/plugins" ]] || return 1
  return 0
}

resolve_groot_home() {
  local explicit="${1:-}"
  if [[ -n "$explicit" ]]; then
    if validate_community_root "$explicit"; then
      cd "$explicit" >/dev/null 2>&1 && pwd
      return
    fi
    echo "--groot-home does not point to a valid Community bundle: $explicit" >&2
    exit 1
  fi

  if [[ -n "${GROOT_HOME:-}" ]]; then
    if validate_community_root "$GROOT_HOME"; then
      cd "$GROOT_HOME" >/dev/null 2>&1 && pwd
      return
    fi
    echo "GROOT_HOME is set but does not point to a valid Community bundle: $GROOT_HOME" >&2
    exit 1
  fi

  local pwd_dir
  pwd_dir="$(pwd)"
  if validate_community_root "$pwd_dir"; then
    echo "$pwd_dir"
    return
  fi

  if validate_community_root "$SCRIPT_DIR"; then
    echo "$SCRIPT_DIR"
    return
  fi

  cat >&2 <<'EOF'
Unable to resolve the target Community bundle.

Set GROOT_HOME to your Community bundle root or pass:
  --groot-home /path/to/groot-community
EOF
  exit 1
}

resolve_sdk_root() {
  local groot_home="$1"
  if [[ -f "$groot_home/sdk/go.mod" ]]; then
    echo "$groot_home/sdk"
    return
  fi

  local source_sdk="$SCRIPT_DIR/../../../sdk"
  if [[ -f "$source_sdk/go.mod" ]]; then
    cd "$source_sdk" >/dev/null 2>&1 && pwd
    return
  fi

  cat >&2 <<'EOF'
Unable to locate the Groot plugin SDK.

Expected one of:
  $GROOT_HOME/sdk/go.mod
  deploy/docker-compose/community/../../../sdk/go.mod

Sync the public Community repo again or run from the main Groot source tree.
EOF
  exit 1
}

metadata_file_for_groot_home() {
  local groot_home="$1"
  echo "$groot_home/integrations/first_party_plugins.json"
}

community_env_file_for_groot_home() {
  local groot_home="$1"
  if [[ -f "$groot_home/.env" ]]; then
    echo "$groot_home/.env"
    return
  fi
  if [[ -f "$groot_home/.env.example" ]]; then
    echo "$groot_home/.env.example"
    return
  fi
  echo ""
}

read_env_value_from_file() {
  local env_file="$1"
  local key="$2"
  if [[ -z "$env_file" || ! -f "$env_file" ]]; then
    echo ""
    return
  fi
  python3 - <<'PY' "$env_file" "$key"
from pathlib import Path
import sys

path = Path(sys.argv[1])
key = sys.argv[2]
for line in path.read_text().splitlines():
    if line.startswith(key + "="):
        print(line.split("=", 1)[1].strip())
        break
PY
}

ensure_template_root() {
  local template_root="$SCRIPT_DIR/plugin-template"
  if [[ ! -d "$template_root" ]]; then
    echo "Missing plugin template directory: $template_root" >&2
    exit 1
  fi
  echo "$template_root"
}

render_template_dir() {
  local template_root="$1"
  local target_dir="$2"
  local integration_name="$3"
  local display_name="$4"
  local struct_name="$5"
  local module_path="$6"

  TEMPLATE_ROOT="$template_root" TARGET_DIR="$target_dir" \
  INTEGRATION_NAME="$integration_name" DISPLAY_NAME="$display_name" \
  STRUCT_NAME="$struct_name" MODULE_PATH="$module_path" \
  python3 - <<'PY'
from pathlib import Path
import os

template_root = Path(os.environ["TEMPLATE_ROOT"])
target_dir = Path(os.environ["TARGET_DIR"])
replacements = {
    "__INTEGRATION_NAME__": os.environ["INTEGRATION_NAME"],
    "__DISPLAY_NAME__": os.environ["DISPLAY_NAME"],
    "__STRUCT_NAME__": os.environ["STRUCT_NAME"],
    "__MODULE_PATH__": os.environ["MODULE_PATH"],
}

for source in template_root.rglob("*"):
    relative = source.relative_to(template_root)
    if source.is_dir():
        (target_dir / relative).mkdir(parents=True, exist_ok=True)
        continue
    destination = target_dir / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    content = source.read_text()
    for needle, value in replacements.items():
        content = content.replace(needle, value)
    destination.write_text(content)
PY
}

scaffold_integration_repo() {
  local integration_name="$1"
  shift

  local target_dir=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --path)
        target_dir="${2:-}"
        shift 2
        ;;
      *)
        echo "Unknown integration init option: $1" >&2
        exit 1
        ;;
    esac
  done

  local normalized_name display_name struct_name template_root module_path
  normalized_name="$(normalize_integration_name "$integration_name")"
  display_name="$(display_name_for_integration "$normalized_name")"
  struct_name="$(struct_name_for_integration "$normalized_name")"
  template_root="$(ensure_template_root)"

  if [[ -z "$target_dir" ]]; then
    target_dir="$(pwd)"
  fi

  mkdir -p "$target_dir"
  if find "$target_dir" -mindepth 1 -maxdepth 1 ! -name '.git' ! -name '.gitignore' | grep -q .; then
    echo "Refusing to scaffold into a non-empty directory: $target_dir" >&2
    exit 1
  fi

  module_path="$(module_path_for_repo "$target_dir")"
  render_template_dir "$template_root" "$target_dir" "$normalized_name" "$display_name" "$struct_name" "$module_path"

  echo "Created plugin repository scaffold."
  echo "Integration: $normalized_name"
  echo "Path:        $target_dir"
  echo
  echo "Next steps:"
  echo "  1. Update the generated files with your integration logic."
  echo "  2. Build it into your Community bundle with:"
  echo "       groot integration build \"$target_dir\""
}

write_plugin_verifier_source() {
  local verify_dir="$1"
  local sdk_replace="$2"
  python3 - <<'PY' "$verify_dir" "$sdk_replace"
from pathlib import Path
import sys

verify_dir = Path(sys.argv[1])
sdk_replace = sys.argv[2]

(verify_dir / "go.mod").write_text(f"""module groot

go 1.23.0

require groot/sdk v0.0.0

replace groot/sdk => {sdk_replace}
""")

(verify_dir / "main.go").write_text(r'''package main

import (
	"encoding/json"
	"fmt"
	"os"
	pluginpkg "plugin"

	sdkintegration "groot/sdk/integration"
)

type manifestSummary struct {
	Name      string `json:"name"`
	Version   string `json:"version,omitempty"`
	Publisher string `json:"publisher,omitempty"`
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "expected plugin path")
		os.Exit(1)
	}
	plug, err := pluginpkg.Open(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "open plugin: %v\n", err)
		os.Exit(1)
	}
	symbol, err := plug.Lookup("Integration")
	if err != nil {
		fmt.Fprintf(os.Stderr, "lookup Integration symbol: %v\n", err)
		os.Exit(1)
	}

	switch exported := symbol.(type) {
	case *sdkintegration.IntegrationPlugin:
		if exported == nil || *exported == nil {
			fmt.Fprintln(os.Stderr, "Integration symbol is nil")
			os.Exit(1)
		}
		writeSummary((*exported).Manifest())
	case *sdkintegration.Integration:
		if exported == nil || *exported == nil {
			fmt.Fprintln(os.Stderr, "Integration symbol is nil")
			os.Exit(1)
		}
		writeSummary(sdkintegration.LegacySpecToManifest((*exported).Spec()))
	default:
		fmt.Fprintf(os.Stderr, "unexpected Integration symbol type %T\n", symbol)
		os.Exit(1)
	}
}

func writeSummary(manifest sdkintegration.Manifest) {
	body, err := json.Marshal(manifestSummary{
		Name:      manifest.Name,
		Version:   manifest.Version,
		Publisher: manifest.Publisher,
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "marshal manifest summary: %v\n", err)
		os.Exit(1)
	}
	fmt.Println(string(body))
}
''')
PY
}

verify_plugin_artifact_host() {
  local artifact="$1"
  local sdk_root="$2"
  (
    set -euo pipefail
    local verify_dir
    verify_dir="$(mktemp -d)"
    trap "rm -rf '$verify_dir'" EXIT

    write_plugin_verifier_source "$verify_dir" "$sdk_root"

    cd "$verify_dir"
    go run . "$artifact"
  )
}

verify_plugin_artifact_linux() {
  local artifact="$1"
  local sdk_root="$2"
  require_docker
  (
    set -euo pipefail
    local verify_dir artifact_dir artifact_name
    verify_dir="$(mktemp -d)"
    artifact_dir="$(cd "$(dirname "$artifact")" >/dev/null 2>&1 && pwd)"
    artifact_name="$(basename "$artifact")"
    trap "rm -rf '$verify_dir'" EXIT

    write_plugin_verifier_source "$verify_dir" "/sdk"

    docker run --rm \
      -v "$verify_dir:/verify" \
      -v "$sdk_root:/sdk:ro" \
      -v "$artifact_dir:/artifact:ro" \
      -w /verify \
      golang:1.23-bookworm \
      bash -lc "export PATH=/usr/local/go/bin:\$PATH && go run . /artifact/$artifact_name"
  )
}

build_plugin_for_linux_runtime() {
  local plugin_repo="$1"
  local sdk_root="$2"
  local artifact_name="$3"
  local output_path="$4"
  require_docker
  (
    set -euo pipefail
    local temp_repo temp_out
    temp_repo="$(mktemp -d)"
    temp_out="$(mktemp -d)"
    trap "rm -rf '$temp_repo' '$temp_out'" EXIT

    cp -R "$plugin_repo/." "$temp_repo/"

    python3 - <<'PY' "$temp_repo/go.mod"
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text().rstrip() + "\n"
lines = []
replaced = False
for line in text.splitlines():
    if line.strip().startswith("replace groot/sdk =>"):
        lines.append("replace groot/sdk => /sdk")
        replaced = True
    else:
        lines.append(line)
if not replaced:
    if lines and lines[-1] != "":
        lines.append("")
    lines.append("replace groot/sdk => /sdk")
path.write_text("\n".join(lines) + "\n")
PY

    docker run --rm \
      -v "$temp_repo:/plugin" \
      -v "$sdk_root:/sdk:ro" \
      -v "$temp_out:/out" \
      -w /plugin \
      golang:1.23-bookworm \
      bash -lc "export PATH=/usr/local/go/bin:\$PATH && go mod download && GOOS=linux GOARCH=\$(go env GOARCH) go build -buildmode=plugin -o /out/$artifact_name ."

    mv "$temp_out/$artifact_name" "$output_path"
  )
}

build_local_integration() {
  local plugin_repo=""
  local explicit_groot_home=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --groot-home)
        explicit_groot_home="${2:-}"
        shift 2
        ;;
      -*)
        echo "Unknown integration build option: $1" >&2
        exit 1
        ;;
      *)
        if [[ -n "$plugin_repo" ]]; then
          echo "Only one plugin repository path may be provided." >&2
          exit 1
        fi
        plugin_repo="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$plugin_repo" ]]; then
    plugin_repo="$(pwd)"
  fi
  if [[ ! -d "$plugin_repo" ]]; then
    echo "Plugin repository directory not found: $plugin_repo" >&2
    exit 1
  fi

  local required
  for required in go.mod provider.go config.go validate.go operations.go schemas.go; do
    if [[ ! -f "$plugin_repo/$required" ]]; then
      echo "Plugin repository is missing required file: $plugin_repo/$required" >&2
      exit 1
    fi
  done

  local groot_home sdk_root plugin_repo_abs output_dir manifest_json plugin_name artifact_name output_path staged_path temp_artifact
  groot_home="$(resolve_groot_home "$explicit_groot_home")"
  sdk_root="$(resolve_sdk_root "$groot_home")"
  plugin_repo_abs="$(cd "$plugin_repo" >/dev/null 2>&1 && pwd)"
  output_dir="$groot_home/integrations/plugins"
  mkdir -p "$output_dir"

  artifact_name="$(basename "$plugin_repo_abs")"
  artifact_name="$(printf '%s' "$artifact_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//')"
  if [[ -z "$artifact_name" ]]; then
    artifact_name="integration-plugin"
  fi
  temp_artifact="$(mktemp "${output_dir}/${artifact_name}.build.XXXXXX")"
  rm -f "$temp_artifact"
  temp_artifact="${temp_artifact}.so"
  build_plugin_for_linux_runtime "$plugin_repo_abs" "$sdk_root" "${artifact_name}.so" "$temp_artifact"

  manifest_json="$(verify_plugin_artifact_linux "$temp_artifact" "$sdk_root")"
  plugin_name="$(python3 - <<'PY' "$manifest_json"
import json
import sys

manifest = json.loads(sys.argv[1])
name = str(manifest.get("name", "")).strip()
if not name:
    raise SystemExit(1)
print(name)
PY
)"
  artifact_name="${plugin_name}.so"
  output_path="$output_dir/$artifact_name"

  staged_path="$(mktemp "$output_dir/${artifact_name}.tmp.XXXXXX")"
  mv "$temp_artifact" "$staged_path"
  mv "$staged_path" "$output_path"

  echo "Built plugin successfully."
  echo "Plugin:      $plugin_name"
  echo "Source repo: $plugin_repo_abs"
  echo "Artifact:    $output_path"
  echo "Runtime:     Linux Docker container (.so built for the Community API image)"
  echo
  echo "Next step:"
  echo "  cd \"$groot_home\" && groot restart"
}

verify_installed_plugins() {
  local explicit_groot_home="${1:-}"
  local groot_home metadata_path plugin_dir env_file api_image
  groot_home="$(resolve_groot_home "$explicit_groot_home")"
  metadata_path="$(metadata_file_for_groot_home "$groot_home")"
  plugin_dir="$groot_home/integrations/plugins"
  env_file="$(community_env_file_for_groot_home "$groot_home")"
  api_image="$(read_env_value_from_file "$env_file" "GROOT_API_IMAGE")"

  if [[ ! -f "$metadata_path" ]]; then
    echo "Missing first-party plugin metadata file: $metadata_path" >&2
    exit 1
  fi
  if [[ -z "$api_image" ]]; then
    echo "Unable to resolve GROOT_API_IMAGE from the Community bundle environment." >&2
    exit 1
  fi
  require_docker

  echo "Community bundle: $groot_home"
  echo "Plugin metadata:  $metadata_path"
  echo "Plugin dir:       $plugin_dir"
  echo "API image:       $api_image"
  echo

  docker run --rm \
    -v "$groot_home/integrations:/app/integrations:ro" \
    -e GROOT_INTEGRATION_PLUGIN_DIR=/app/integrations/plugins \
    -e GROOT_INTEGRATION_FIRST_PARTY_PLUGINS_PATH=/app/integrations/first_party_plugins.json \
    "$api_image" verify-plugins
}

handle_integration_command() {
  local subcommand="${1:-}"
  shift || true

  case "$subcommand" in
    init)
      if [[ $# -lt 1 ]]; then
        echo "Usage: groot integration init <name> [--path <dir>]" >&2
        exit 1
      fi
      local integration_name="$1"
      shift
      scaffold_integration_repo "$integration_name" "$@"
      ;;
    build)
      build_local_integration "$@"
      ;;
    verify)
      local explicit_groot_home=""
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --groot-home)
            explicit_groot_home="${2:-}"
            shift 2
            ;;
          *)
            echo "Unknown integration verify option: $1" >&2
            exit 1
            ;;
        esac
      done
      verify_installed_plugins "$explicit_groot_home"
      ;;
    install|remove|list|info)
      cat >&2 <<'EOF'
The Community bundle only supports local plugin scaffolding and build/install workflows.

Packaged plugin distribution commands are available from the main Groot CLI in the
full source repository.
EOF
      exit 1
      ;;
    ""|-h|--help|help)
      cat <<'EOF'
Usage:
  groot integration init <name> [--path <dir>]
  groot integration build [<plugin-repo>] [--groot-home <community-dir>]
  groot integration verify [--groot-home <community-dir>]
EOF
      ;;
    *)
      echo "Unknown integration subcommand: $subcommand" >&2
      exit 1
      ;;
  esac
}
