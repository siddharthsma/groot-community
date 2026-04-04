ALTER TABLE connector_instances
ADD COLUMN IF NOT EXISTS secret_refs_json JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE TABLE IF NOT EXISTS connection_secret_values (
    id UUID PRIMARY KEY,
    connection_id UUID NOT NULL REFERENCES connector_instances(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    backend TEXT NOT NULL,
    ciphertext BYTEA NOT NULL,
    nonce BYTEA NOT NULL,
    key_version INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    rotated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS connection_secret_values_connection_field_uq
    ON connection_secret_values (connection_id, field_name);
