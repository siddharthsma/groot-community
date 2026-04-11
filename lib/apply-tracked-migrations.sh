#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: apply-tracked-migrations.sh --migrations-dir <dir> --psql-command <command> [--baseline-file <name>]

Applies pending SQL migrations from a flat directory using a schema_migrations
ledger. If the ledger is absent but the database already contains Groot tables,
the baseline migration is marked as applied without being executed.
EOF
}

MIGRATIONS_DIR=""
PSQL_COMMAND=""
BASELINE_FILE="001_baseline.sql"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --migrations-dir)
      MIGRATIONS_DIR="${2:-}"
      shift 2
      ;;
    --psql-command)
      PSQL_COMMAND="${2:-}"
      shift 2
      ;;
    --baseline-file)
      BASELINE_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$MIGRATIONS_DIR" || -z "$PSQL_COMMAND" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -d "$MIGRATIONS_DIR" ]]; then
  echo "missing migrations directory: $MIGRATIONS_DIR" >&2
  exit 1
fi

run_psql() {
  local sql="$1"
  printf '%s\n' "$sql" | eval "$PSQL_COMMAND"
}

query_scalar() {
  local sql="$1"
  printf '%s\n' "$sql" | eval "$PSQL_COMMAND -Atq"
}

sql_literal() {
  local value="$1"
  value="${value//\'/\'\'}"
  printf "'%s'" "$value"
}

ensure_ledger() {
  run_psql "
CREATE TABLE IF NOT EXISTS public.schema_migrations (
    version text PRIMARY KEY,
    applied_at timestamp with time zone NOT NULL DEFAULT now()
);
"
}

has_existing_schema() {
  local result
  result="$(query_scalar "
SELECT CASE
  WHEN to_regclass('public.tenants') IS NOT NULL THEN 't'
  WHEN to_regclass('public.events') IS NOT NULL THEN 't'
  WHEN EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name <> 'schema_migrations'
  ) THEN 't'
  ELSE 'f'
END;
")"
  [[ "$result" == "t" ]]
}

has_ledger() {
  local result
  result="$(query_scalar "SELECT CASE WHEN to_regclass('public.schema_migrations') IS NOT NULL THEN 't' ELSE 'f' END;")"
  [[ "$result" == "t" ]]
}

is_applied() {
  local version="$1"
  local result
  result="$(query_scalar "SELECT CASE WHEN EXISTS (SELECT 1 FROM public.schema_migrations WHERE version = $(sql_literal "$version")) THEN 't' ELSE 'f' END;")"
  [[ "$result" == "t" ]]
}

mark_applied() {
  local version="$1"
  run_psql "INSERT INTO public.schema_migrations (version) VALUES ($(sql_literal "$version")) ON CONFLICT (version) DO NOTHING;"
}

apply_file() {
  local file="$1"
  local version
  version="$(basename "$file")"
  {
    printf 'BEGIN;\n'
    cat "$file"
    printf '\nINSERT INTO public.schema_migrations (version) VALUES (%s);\n' "$(sql_literal "$version")"
    printf 'COMMIT;\n'
  } | eval "$PSQL_COMMAND"
}

if [[ ! -f "$MIGRATIONS_DIR/$BASELINE_FILE" ]]; then
  echo "missing baseline migration: $MIGRATIONS_DIR/$BASELINE_FILE" >&2
  exit 1
fi

if ! has_ledger; then
  ensure_ledger
  if has_existing_schema; then
    mark_applied "$BASELINE_FILE"
  fi
fi

while IFS= read -r file; do
  version="$(basename "$file")"
  if is_applied "$version"; then
    continue
  fi
  apply_file "$file"
done < <(find "$MIGRATIONS_DIR" -maxdepth 1 -type f -name '*.sql' | sort)
