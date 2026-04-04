ALTER TABLE IF EXISTS agent_runs
    DROP CONSTRAINT IF EXISTS agent_runs_subscription_id_fkey;

ALTER TABLE IF EXISTS workflow_run_steps
    DROP CONSTRAINT IF EXISTS workflow_run_steps_subscription_id_fkey;

DROP TABLE IF EXISTS subscriptions;

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    agent_version_id UUID NULL REFERENCES agent_versions(id),
    kind TEXT NOT NULL,
    status TEXT NOT NULL,
    match_json JSONB NOT NULL,
    action_json JSONB NOT NULL,
    emit_success_event BOOLEAN NOT NULL DEFAULT FALSE,
    emit_failure_event BOOLEAN NOT NULL DEFAULT FALSE,
    created_by_kind TEXT,
    parent_event_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_tenant_status_created
    ON subscriptions (tenant_id, status, created_at);

CREATE INDEX idx_subscriptions_match_json
    ON subscriptions
    USING GIN (match_json);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'agent_runs'
    ) AND NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'agent_runs_subscription_id_fkey'
    ) THEN
        ALTER TABLE agent_runs
            ADD CONSTRAINT agent_runs_subscription_id_fkey
            FOREIGN KEY (subscription_id) REFERENCES subscriptions(id);
    END IF;
END $$;
