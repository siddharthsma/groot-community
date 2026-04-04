DROP TABLE IF EXISTS phase67_connected_app_connection_map;
CREATE TEMP TABLE phase67_connected_app_connection_map (
    connected_app_id UUID,
    connection_id UUID
);

DROP TABLE IF EXISTS phase67_function_connection_map;
CREATE TEMP TABLE phase67_function_connection_map (
    function_destination_id UUID,
    connection_id UUID
);

DO $$
BEGIN
    IF to_regclass('public.connected_apps') IS NOT NULL THEN
        INSERT INTO phase67_connected_app_connection_map (connected_app_id, connection_id)
        SELECT
            ca.id,
            (
                substr(md5('connected_app:' || ca.id::text), 1, 8) || '-' ||
                substr(md5('connected_app:' || ca.id::text), 9, 4) || '-' ||
                substr(md5('connected_app:' || ca.id::text), 13, 4) || '-' ||
                substr(md5('connected_app:' || ca.id::text), 17, 4) || '-' ||
                substr(md5('connected_app:' || ca.id::text), 21, 12)
            )::uuid
        FROM connected_apps ca;
    END IF;

    IF to_regclass('public.function_destinations') IS NOT NULL THEN
        INSERT INTO phase67_function_connection_map (function_destination_id, connection_id)
        SELECT
            fd.id,
            (
                substr(md5('function_destination:' || fd.id::text), 1, 8) || '-' ||
                substr(md5('function_destination:' || fd.id::text), 9, 4) || '-' ||
                substr(md5('function_destination:' || fd.id::text), 13, 4) || '-' ||
                substr(md5('function_destination:' || fd.id::text), 17, 4) || '-' ||
                substr(md5('function_destination:' || fd.id::text), 21, 12)
            )::uuid
        FROM function_destinations fd;
    END IF;
END $$;

INSERT INTO connector_instances (
    id,
    tenant_id,
    owner_tenant_id,
    label,
    connector_name,
    scope,
    status,
    config_json,
    created_at,
    updated_at
)
SELECT
    m.connection_id,
    ca.tenant_id,
    ca.tenant_id,
    ca.name,
    'webhook',
    'tenant',
    'enabled',
    jsonb_build_object('destination_url', ca.destination_url),
    ca.created_at,
    ca.created_at
FROM connected_apps ca
INNER JOIN phase67_connected_app_connection_map m ON m.connected_app_id = ca.id
ON CONFLICT (id) DO NOTHING;

INSERT INTO connector_instances (
    id,
    tenant_id,
    owner_tenant_id,
    label,
    connector_name,
    scope,
    status,
    config_json,
    created_at,
    updated_at
)
SELECT
    m.connection_id,
    fd.tenant_id,
    fd.tenant_id,
    fd.name,
    'function',
    'tenant',
    'enabled',
    jsonb_build_object(
        'url', fd.url,
        'secret', fd.secret,
        'timeout_seconds', fd.timeout_seconds
    ),
    fd.created_at,
    fd.created_at
FROM function_destinations fd
INNER JOIN phase67_function_connection_map m ON m.function_destination_id = fd.id
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'subscriptions'
          AND column_name = 'connected_app_id'
    ) THEN
        UPDATE subscriptions s
        SET connector_instance_id = m.connection_id,
            destination_type = 'connection',
            operation = COALESCE(NULLIF(BTRIM(s.operation), ''), 'deliver'),
            operation_params = COALESCE(s.operation_params, '{}'::jsonb)
        FROM phase67_connected_app_connection_map m
        WHERE s.connected_app_id = m.connected_app_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'subscriptions'
          AND column_name = 'function_destination_id'
    ) THEN
        UPDATE subscriptions s
        SET connector_instance_id = m.connection_id,
            destination_type = 'connection',
            operation = COALESCE(NULLIF(BTRIM(s.operation), ''), 'invoke'),
            operation_params = COALESCE(s.operation_params, '{}'::jsonb)
        FROM phase67_function_connection_map m
        WHERE s.function_destination_id = m.function_destination_id;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM subscriptions
        WHERE connector_instance_id IS NULL
    ) THEN
        RAISE EXCEPTION 'phase67 migration requires every subscription to resolve to a connection';
    END IF;
END $$;

UPDATE agents a
SET tool_bindings = rewritten.tool_bindings
FROM (
    SELECT
        current.id,
        COALESCE(
            (
                SELECT jsonb_object_agg(
                    binding.key,
                    CASE
                        WHEN binding.value->>'type' = 'function' AND binding.value ? 'function_destination_id' THEN jsonb_build_object(
                            'type', 'connection',
                            'connection_id', map.connection_id::text,
                            'operation', 'invoke'
                        )
                        ELSE binding.value - 'integration_name' - 'function_destination_id'
                    END
                )
                FROM jsonb_each(current.tool_bindings) AS binding(key, value)
                LEFT JOIN phase67_function_connection_map map
                    ON CASE
                        WHEN binding.value ? 'function_destination_id'
                        THEN (binding.value->>'function_destination_id')::uuid
                        ELSE NULL
                    END = map.function_destination_id
            ),
            '{}'::jsonb
        ) AS tool_bindings
    FROM agents current
) AS rewritten
WHERE a.id = rewritten.id;

UPDATE agent_versions v
SET tool_bindings = rewritten.tool_bindings
FROM (
    SELECT
        current.id,
        COALESCE(
            (
                SELECT jsonb_object_agg(
                    binding.key,
                    CASE
                        WHEN binding.value->>'type' = 'function' AND binding.value ? 'function_destination_id' THEN jsonb_build_object(
                            'type', 'connection',
                            'connection_id', map.connection_id::text,
                            'operation', 'invoke'
                        )
                        ELSE binding.value - 'integration_name' - 'function_destination_id'
                    END
                )
                FROM jsonb_each(current.tool_bindings) AS binding(key, value)
                LEFT JOIN phase67_function_connection_map map
                    ON CASE
                        WHEN binding.value ? 'function_destination_id'
                        THEN (binding.value->>'function_destination_id')::uuid
                        ELSE NULL
                    END = map.function_destination_id
            ),
            '{}'::jsonb
        ) AS tool_bindings
    FROM agent_versions current
) AS rewritten
WHERE v.id = rewritten.id;

ALTER TABLE subscriptions
DROP COLUMN IF EXISTS connected_app_id,
DROP COLUMN IF EXISTS function_destination_id;

DROP TABLE IF EXISTS connected_apps;
DROP TABLE IF EXISTS function_destinations;
