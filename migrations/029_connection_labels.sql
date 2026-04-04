ALTER TABLE connector_instances
ADD COLUMN IF NOT EXISTS label TEXT;

WITH ranked AS (
    SELECT
        id,
        CASE connector_name
            WHEN 'clickup' THEN 'ClickUp'
            WHEN 'hubspot' THEN 'HubSpot'
            WHEN 'llm' THEN 'LLM'
            ELSE INITCAP(REPLACE(connector_name, '_', ' '))
        END AS base_name,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(owner_tenant_id::text, tenant_id::text), connector_name
            ORDER BY created_at ASC, id ASC
        ) AS ordinal
    FROM connector_instances
)
UPDATE connector_instances ci
SET label = CASE
    WHEN ranked.ordinal = 1 THEN ranked.base_name || ' connection'
    ELSE ranked.base_name || ' connection ' || ranked.ordinal
END
FROM ranked
WHERE ci.id = ranked.id
  AND (ci.label IS NULL OR BTRIM(ci.label) = '');

ALTER TABLE connector_instances
ALTER COLUMN label SET NOT NULL;

DROP INDEX IF EXISTS connector_instances_owner_label_uq;

CREATE UNIQUE INDEX IF NOT EXISTS connector_instances_owner_label_uq
    ON connector_instances (COALESCE(owner_tenant_id, tenant_id), label);
