UPDATE subscriptions AS s
SET action_json = jsonb_strip_nulls(jsonb_build_object(
    'type', 'agent',
    'agent_id', s.action_json->'agent_id',
    'session_key_template', s.action_json->'session_key_template',
    'session_create_if_missing', COALESCE((s.action_json->>'session_create_if_missing')::boolean, true),
    'params', '{}'::jsonb
))
FROM connector_instances AS ci
WHERE s.action_json->>'type' = 'agent'
  AND s.action_json ? 'connection_id'
  AND ci.id = NULLIF(BTRIM(s.action_json->>'connection_id'), '')::uuid
  AND ci.connector_name = 'llm';
