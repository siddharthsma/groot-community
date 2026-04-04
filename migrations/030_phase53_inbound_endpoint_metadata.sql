ALTER TABLE inbound_routes
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'enabled',
ADD COLUMN IF NOT EXISTS metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP NOT NULL DEFAULT NOW();

UPDATE inbound_routes
SET metadata_json = '{}'::jsonb
WHERE metadata_json IS NULL;

UPDATE inbound_routes
SET updated_at = created_at
WHERE updated_at IS NULL;

ALTER TABLE inbound_routes
DROP CONSTRAINT IF EXISTS inbound_routes_status_check;

ALTER TABLE inbound_routes
ADD CONSTRAINT inbound_routes_status_check
CHECK (status IN ('enabled', 'disabled'));
