ALTER TABLE agent_sessions
  ALTER COLUMN status SET DEFAULT 'running';

UPDATE agent_sessions
SET status = 'running'
WHERE status = 'active';

ALTER TABLE agent_sessions
  DROP CONSTRAINT IF EXISTS agent_sessions_status_check;

ALTER TABLE agent_sessions
  ADD CONSTRAINT agent_sessions_status_check
  CHECK (status IN ('running', 'waiting', 'closed', 'failed'));

CREATE TABLE IF NOT EXISTS agent_session_waits (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  agent_session_id UUID NOT NULL REFERENCES agent_sessions(id),
  agent_run_id UUID NOT NULL REFERENCES agent_runs(id),
  subscription_id UUID NOT NULL REFERENCES subscriptions(id),
  tool_name TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'resumed', 'expired', 'cancelled')),
  timeout_at TIMESTAMP NULL,
  resumed_at TIMESTAMP NULL,
  resume_event_id UUID NULL REFERENCES events(event_id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_session_waits_session
ON agent_session_waits(agent_session_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_agent_session_waits_subscription
ON agent_session_waits(subscription_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_agent_session_waits_one_active_per_session
ON agent_session_waits(agent_session_id)
WHERE status = 'active';
