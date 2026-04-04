ALTER TABLE connector_instances
    ADD COLUMN IF NOT EXISTS status_reason TEXT NULL,
    ADD COLUMN IF NOT EXISTS setup_diagnostics_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS setup_outputs_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS last_setup_action TEXT NULL,
    ADD COLUMN IF NOT EXISTS last_setup_at TIMESTAMP NULL;

UPDATE connector_instances
SET status = 'active'
WHERE status = 'enabled';
