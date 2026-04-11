CREATE TABLE IF NOT EXISTS public.connection_oauth_bootstraps (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES public.tenants(id),
    integration_name text NOT NULL,
    status text NOT NULL,
    state_token text NOT NULL,
    config_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    redirect_path text,
    provider_context_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    result_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    error_text text,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS connection_oauth_bootstraps_state_token_uq
    ON public.connection_oauth_bootstraps (state_token);

CREATE INDEX IF NOT EXISTS connection_oauth_bootstraps_tenant_status_idx
    ON public.connection_oauth_bootstraps (tenant_id, status, expires_at, updated_at);
