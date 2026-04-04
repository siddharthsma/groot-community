CREATE TABLE IF NOT EXISTS agent_session_histories (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  agent_session_id UUID NOT NULL REFERENCES agent_sessions(id),
  agent_run_id UUID REFERENCES agent_runs(id),
  version INTEGER NOT NULL,
  messages JSONB NOT NULL,
  message_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS agent_session_histories_session_version_uq
ON agent_session_histories(agent_session_id, version);

CREATE INDEX IF NOT EXISTS agent_session_histories_tenant_session_created_idx
ON agent_session_histories(tenant_id, agent_session_id, created_at DESC);
