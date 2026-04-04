WITH ranked AS (
	SELECT id,
	       ROW_NUMBER() OVER (
		       PARTITION BY connector_instance_id
		       ORDER BY updated_at DESC, created_at DESC, id DESC
	       ) AS rn
	FROM inbound_routes
)
DELETE FROM inbound_routes
WHERE id IN (
	SELECT id
	FROM ranked
	WHERE rn > 1
);

CREATE UNIQUE INDEX IF NOT EXISTS inbound_routes_connection_uq
ON inbound_routes(connector_instance_id);
