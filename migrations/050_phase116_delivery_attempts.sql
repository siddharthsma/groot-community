CREATE TABLE IF NOT EXISTS delivery_attempts (
    id UUID PRIMARY KEY,
    delivery_job_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    attempt INT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ NULL,
    status TEXT NOT NULL,
    error_summary TEXT NULL,
    status_code INT NULL,
    external_id TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_delivery_attempts_tenant_job_started
    ON delivery_attempts (tenant_id, delivery_job_id, started_at DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_delivery_attempts_job_attempt
    ON delivery_attempts (delivery_job_id, attempt, created_at DESC);
