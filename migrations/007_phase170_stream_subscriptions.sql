CREATE TABLE IF NOT EXISTS public.connection_stream_subscriptions (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES public.tenants(id),
    connection_id uuid NOT NULL REFERENCES public.connector_instances(id) ON DELETE CASCADE,
    integration_name text NOT NULL,
    status text NOT NULL,
    lease_owner text,
    lease_expires_at timestamp with time zone,
    checkpoint_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    setup_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    last_error text,
    last_event_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS connection_stream_subscriptions_connection_uq
    ON public.connection_stream_subscriptions (connection_id, integration_name);

CREATE INDEX IF NOT EXISTS connection_stream_subscriptions_active_lease_idx
    ON public.connection_stream_subscriptions (status, lease_expires_at, updated_at);
