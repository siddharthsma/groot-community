UPDATE connector_instances
SET
    connector_name = 'http',
    config_json = CASE
        WHEN connector_name = 'webhook' THEN jsonb_build_object(
            'url', config_json->>'destination_url',
            'sign_requests', false
        )
        WHEN connector_name = 'function' THEN jsonb_strip_nulls(jsonb_build_object(
            'url', config_json->>'url',
            'timeout_seconds', config_json->'timeout_seconds',
            'headers', config_json->'headers',
            'secret', config_json->>'secret',
            'sign_requests', true
        ))
        ELSE config_json
    END
WHERE connector_name IN ('webhook', 'function');

UPDATE subscriptions s
SET operation = 'invoke'
FROM connector_instances ci
WHERE s.connector_instance_id = ci.id
  AND ci.connector_name = 'http'
  AND COALESCE(NULLIF(BTRIM(s.operation), ''), 'invoke') = 'deliver';

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
                        WHEN binding.value->>'type' = 'connection'
                             AND binding.value->>'operation' = 'deliver'
                             AND ci.connector_name = 'http'
                        THEN jsonb_set(binding.value, '{operation}', to_jsonb('invoke'::text), true)
                        ELSE binding.value
                    END
                    ORDER BY binding.key
                )
                FROM jsonb_each(current.tool_bindings) AS binding(key, value)
                LEFT JOIN connector_instances ci
                    ON CASE
                        WHEN binding.value ? 'connection_id'
                        THEN (binding.value->>'connection_id')::uuid
                        ELSE NULL
                    END = ci.id
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
                        WHEN binding.value->>'type' = 'connection'
                             AND binding.value->>'operation' = 'deliver'
                             AND ci.connector_name = 'http'
                        THEN jsonb_set(binding.value, '{operation}', to_jsonb('invoke'::text), true)
                        ELSE binding.value
                    END
                    ORDER BY binding.key
                )
                FROM jsonb_each(current.tool_bindings) AS binding(key, value)
                LEFT JOIN connector_instances ci
                    ON CASE
                        WHEN binding.value ? 'connection_id'
                        THEN (binding.value->>'connection_id')::uuid
                        ELSE NULL
                    END = ci.id
            ),
            '{}'::jsonb
        ) AS tool_bindings
    FROM agent_versions current
) AS rewritten
WHERE v.id = rewritten.id;

UPDATE workflow_versions wv
SET
    definition_json = rewritten.definition_json,
    compiled_json = rewritten.compiled_json,
    compiled_hash = CASE
        WHEN rewritten.definition_json IS DISTINCT FROM wv.definition_json
          OR rewritten.compiled_json IS DISTINCT FROM wv.compiled_json
        THEN NULL
        ELSE wv.compiled_hash
    END
FROM (
    SELECT
        current.id,
        CASE
            WHEN current.definition_json IS NULL
              OR jsonb_typeof(current.definition_json->'nodes') <> 'array'
            THEN current.definition_json
            ELSE jsonb_set(
                current.definition_json,
                '{nodes}',
                (
                    SELECT jsonb_agg(
                        CASE
                            WHEN node.value->>'type' = 'action'
                                 AND node.value->'config'->>'integration' IN ('webhook', 'function')
                            THEN jsonb_set(
                                jsonb_set(
                                    node.value,
                                    '{config,integration}',
                                    to_jsonb('http'::text),
                                    true
                                ),
                                '{config,operation}',
                                to_jsonb(
                                    CASE
                                        WHEN node.value->'config'->>'integration' = 'webhook'
                                        THEN 'invoke'
                                        ELSE COALESCE(NULLIF(BTRIM(node.value->'config'->>'operation'), ''), 'invoke')
                                    END
                                ),
                                true
                            )
                            ELSE node.value
                        END
                        ORDER BY node.ordinality
                    )
                    FROM jsonb_array_elements(current.definition_json->'nodes') WITH ORDINALITY AS node(value, ordinality)
                ),
                true
            )
        END AS definition_json,
        CASE
            WHEN current.compiled_json IS NULL
              OR jsonb_typeof(current.compiled_json->'node_bindings') <> 'array'
            THEN current.compiled_json
            ELSE jsonb_set(
                current.compiled_json,
                '{node_bindings}',
                (
                    SELECT jsonb_agg(
                        CASE
                            WHEN binding.value->>'node_type' = 'action'
                                 AND binding.value->>'integration' IN ('webhook', 'function')
                            THEN jsonb_set(
                                jsonb_set(
                                    binding.value,
                                    '{integration}',
                                    to_jsonb('http'::text),
                                    true
                                ),
                                '{operation}',
                                to_jsonb(
                                    CASE
                                        WHEN binding.value->>'integration' = 'webhook'
                                        THEN 'invoke'
                                        ELSE COALESCE(NULLIF(BTRIM(binding.value->>'operation'), ''), 'invoke')
                                    END
                                ),
                                true
                            )
                            ELSE binding.value
                        END
                        ORDER BY binding.ordinality
                    )
                    FROM jsonb_array_elements(current.compiled_json->'node_bindings') WITH ORDINALITY AS binding(value, ordinality)
                ),
                true
            )
        END AS compiled_json
    FROM workflow_versions current
) AS rewritten
WHERE wv.id = rewritten.id;
