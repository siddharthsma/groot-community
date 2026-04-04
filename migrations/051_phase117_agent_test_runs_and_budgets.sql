ALTER TABLE agent_runs
    ALTER COLUMN subscription_id DROP NOT NULL;

ALTER TABLE agent_runs
    ADD COLUMN IF NOT EXISTS origin_kind TEXT NOT NULL DEFAULT 'subscription',
    ADD COLUMN IF NOT EXISTS test_run_id UUID NULL;

ALTER TABLE agent_runs
    ADD CONSTRAINT agent_runs_origin_kind_chk
    CHECK (origin_kind IN ('subscription', 'test_run'));

CREATE INDEX IF NOT EXISTS agent_runs_agent_started_idx
    ON agent_runs (tenant_id, agent_id, started_at DESC);

CREATE INDEX IF NOT EXISTS agent_runs_origin_kind_idx
    ON agent_runs (tenant_id, origin_kind, started_at DESC);

CREATE TABLE IF NOT EXISTS agent_test_runs (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    agent_id UUID NOT NULL REFERENCES agents(id),
    mode TEXT NOT NULL,
    status TEXT NOT NULL,
    input_event_id UUID NOT NULL REFERENCES events(event_id),
    agent_run_id UUID NULL REFERENCES agent_runs(id),
    agent_session_id UUID NULL REFERENCES agent_sessions(id),
    session_key TEXT NOT NULL,
    last_error TEXT NULL,
    started_at TIMESTAMPTZ NULL,
    completed_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by_actor_type TEXT,
    created_by_actor_id TEXT,
    created_by_actor_email TEXT,
    updated_by_actor_type TEXT,
    updated_by_actor_id TEXT,
    updated_by_actor_email TEXT,
    CONSTRAINT agent_test_runs_mode_chk CHECK (mode IN ('live', 'dry_run')),
    CONSTRAINT agent_test_runs_status_chk CHECK (status IN ('queued', 'running', 'succeeded', 'failed'))
);

CREATE INDEX IF NOT EXISTS agent_test_runs_agent_created_idx
    ON agent_test_runs (tenant_id, agent_id, created_at DESC);

CREATE INDEX IF NOT EXISTS agent_test_runs_event_idx
    ON agent_test_runs (input_event_id);

ALTER TABLE agent_runs
    DROP CONSTRAINT IF EXISTS agent_runs_test_run_id_fkey;

ALTER TABLE agent_runs
    ADD CONSTRAINT agent_runs_test_run_id_fkey
    FOREIGN KEY (test_run_id) REFERENCES agent_test_runs(id);

CREATE TABLE IF NOT EXISTS agent_budgets (
    agent_id UUID PRIMARY KEY REFERENCES agents(id),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    monthly_token_limit BIGINT NOT NULL DEFAULT 0,
    alert_threshold_percent INT NOT NULL DEFAULT 80,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT agent_budgets_monthly_token_limit_chk CHECK (monthly_token_limit >= 0),
    CONSTRAINT agent_budgets_alert_threshold_chk CHECK (alert_threshold_percent BETWEEN 1 AND 100)
);

CREATE INDEX IF NOT EXISTS agent_budgets_tenant_idx
    ON agent_budgets (tenant_id);
