CREATE UNIQUE INDEX IF NOT EXISTS idx_agent_session_histories_agent_run_unique
ON agent_session_histories(agent_run_id)
WHERE agent_run_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_agent_session_waits_resume_event_unique
ON agent_session_waits(resume_event_id)
WHERE resume_event_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS agent_run_tool_calls (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  agent_run_id UUID NOT NULL REFERENCES agent_runs(id),
  agent_session_id UUID NOT NULL REFERENCES agent_sessions(id),
  tool_name TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('succeeded', 'failed')),
  external_id TEXT NULL,
  result_json JSONB NOT NULL,
  integration TEXT NULL,
  model TEXT NULL,
  usage_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  status_code INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_agent_run_tool_calls_run_key_unique
ON agent_run_tool_calls(agent_run_id, idempotency_key);

CREATE INDEX IF NOT EXISTS idx_agent_run_tool_calls_session_created
ON agent_run_tool_calls(agent_session_id, created_at DESC);
