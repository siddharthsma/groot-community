ALTER TABLE subscriptions
    ADD COLUMN match_event_type TEXT;

UPDATE subscriptions AS s
SET match_event_type = matched.event_type
FROM (
    SELECT
        source.id,
        elem->>'value' AS event_type
    FROM subscriptions AS source,
         jsonb_array_elements(source.match_json) AS elem
    WHERE elem->>'path' = 'type'
      AND elem->>'op' = '=='
) AS matched
WHERE s.id = matched.id;

ALTER TABLE subscriptions
    ALTER COLUMN match_event_type SET NOT NULL;

DROP INDEX IF EXISTS idx_subscriptions_tenant_status_created;

CREATE INDEX idx_subscriptions_tenant_status_event_created
    ON subscriptions (tenant_id, status, match_event_type, created_at);
