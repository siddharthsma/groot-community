CREATE TABLE IF NOT EXISTS tenant_settings (
    tenant_id UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    timezone TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS tenant_budgets (
    tenant_id UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    monthly_token_limit BIGINT NOT NULL,
    alert_threshold_percent INTEGER NOT NULL,
    notifications_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT tenant_budgets_monthly_token_limit_chk CHECK (monthly_token_limit >= 0),
    CONSTRAINT tenant_budgets_alert_threshold_chk CHECK (alert_threshold_percent BETWEEN 1 AND 100)
);

CREATE TABLE IF NOT EXISTS analytics_rollup_events_daily (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    integration_name TEXT NOT NULL,
    event_type TEXT NOT NULL,
    count BIGINT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (tenant_id, day, integration_name, event_type)
);

CREATE INDEX IF NOT EXISTS analytics_rollup_events_daily_tenant_day_idx
    ON analytics_rollup_events_daily (tenant_id, day);

CREATE TABLE IF NOT EXISTS analytics_rollup_deliveries_daily (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    status TEXT NOT NULL,
    count BIGINT NOT NULL,
    median_latency_ms DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (tenant_id, day, status)
);

CREATE INDEX IF NOT EXISTS analytics_rollup_deliveries_daily_tenant_day_idx
    ON analytics_rollup_deliveries_daily (tenant_id, day);

CREATE TABLE IF NOT EXISTS analytics_rollup_agent_usage_daily (
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    model TEXT NOT NULL,
    origin_kind TEXT NOT NULL,
    prompt_tokens BIGINT NOT NULL,
    completion_tokens BIGINT NOT NULL,
    total_tokens BIGINT NOT NULL,
    run_count BIGINT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (tenant_id, day, agent_id, model, origin_kind)
);

CREATE INDEX IF NOT EXISTS analytics_rollup_agent_usage_daily_tenant_day_idx
    ON analytics_rollup_agent_usage_daily (tenant_id, day);
