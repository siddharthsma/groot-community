DROP INDEX IF EXISTS event_schemas_full_name_uq;
DROP INDEX IF EXISTS events_schema_full_name_idx;

ALTER TABLE event_schemas
    DROP COLUMN IF EXISTS version,
    DROP COLUMN IF EXISTS full_name;

CREATE UNIQUE INDEX IF NOT EXISTS event_schemas_event_type_uq
    ON event_schemas(event_type);

ALTER TABLE events
    DROP COLUMN IF EXISTS schema_full_name,
    DROP COLUMN IF EXISTS schema_version;
