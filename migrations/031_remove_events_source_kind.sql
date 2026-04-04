ALTER TABLE events
ADD COLUMN IF NOT EXISTS source_json JSONB;

UPDATE events
SET source_json = jsonb_strip_nulls(jsonb_build_object(
	'kind', COALESCE(NULLIF(source_kind, ''), 'external'),
	'integration', NULLIF(source, ''),
	'connection_id', source_connection_id,
	'connection_name', NULLIF(source_connection_name, ''),
	'external_account_id', NULLIF(source_external_account_id, '')
))
WHERE source_json IS NULL;

ALTER TABLE events
ALTER COLUMN source_json SET NOT NULL;

ALTER TABLE events
ALTER COLUMN source_json SET DEFAULT '{"kind":"external"}'::jsonb;

ALTER TABLE events
DROP CONSTRAINT IF EXISTS events_source_kind_chk;

DROP INDEX IF EXISTS events_tenant_source_kind_idx;

ALTER TABLE events
DROP COLUMN IF EXISTS source_kind;
