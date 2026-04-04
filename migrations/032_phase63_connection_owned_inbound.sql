UPDATE inbound_routes AS r
SET connector_instance_id = candidate.connection_id
FROM (
	SELECT
		r2.id AS route_id,
		(
			SELECT ci.id
			FROM connector_instances AS ci
			WHERE ci.owner_tenant_id = r2.tenant_id
			  AND ci.connector_name = r2.connector_name
			  AND ci.scope = 'tenant'
			ORDER BY ci.created_at ASC
			LIMIT 1
		) AS connection_id
	FROM inbound_routes AS r2
	WHERE r2.connector_instance_id IS NULL
) AS candidate
WHERE r.id = candidate.route_id
  AND candidate.connection_id IS NOT NULL;

DO $$
BEGIN
	IF EXISTS (SELECT 1 FROM inbound_routes WHERE connector_instance_id IS NULL) THEN
		RAISE EXCEPTION 'cannot enforce connection-owned inbound routes: unresolved rows remain';
	END IF;
END $$;

ALTER TABLE inbound_routes
ALTER COLUMN connector_instance_id SET NOT NULL;
