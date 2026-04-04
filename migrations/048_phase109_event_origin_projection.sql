ALTER TABLE events
    ADD COLUMN IF NOT EXISTS origin_integration TEXT,
    ADD COLUMN IF NOT EXISTS origin_connection_id UUID,
    ADD COLUMN IF NOT EXISTS origin_connection_name TEXT,
    ADD COLUMN IF NOT EXISTS origin_external_account_id TEXT;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'events' AND column_name = 'lineage_integration'
    ) THEN
        EXECUTE '
            UPDATE events
            SET
                origin_integration = COALESCE(origin_integration, lineage_integration),
                origin_connection_id = COALESCE(origin_connection_id, lineage_connection_id),
                origin_connection_name = COALESCE(origin_connection_name, lineage_connection_name),
                origin_external_account_id = COALESCE(origin_external_account_id, lineage_external_account_id)
        ';
    END IF;
END $$;

DROP INDEX IF EXISTS events_tenant_lineage_connection_id_idx;

CREATE INDEX IF NOT EXISTS events_tenant_origin_connection_id_idx
    ON events(tenant_id, origin_connection_id);

ALTER TABLE events
    DROP COLUMN IF EXISTS lineage_integration,
    DROP COLUMN IF EXISTS lineage_connection_id,
    DROP COLUMN IF EXISTS lineage_connection_name,
    DROP COLUMN IF EXISTS lineage_external_account_id;
