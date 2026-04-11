ALTER TABLE public.agents
    ADD COLUMN IF NOT EXISTS history_strategy text NOT NULL DEFAULT 'all',
    ADD COLUMN IF NOT EXISTS history_strategy_config jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.agent_versions
    ADD COLUMN IF NOT EXISTS history_strategy text NOT NULL DEFAULT 'all',
    ADD COLUMN IF NOT EXISTS history_strategy_config jsonb NOT NULL DEFAULT '{}'::jsonb;

UPDATE public.agents
SET history_strategy = 'all',
    history_strategy_config = '{}'::jsonb
WHERE history_strategy IS NULL
   OR history_strategy = '';

UPDATE public.agent_versions
SET history_strategy = 'all',
    history_strategy_config = '{}'::jsonb
WHERE history_strategy IS NULL
   OR history_strategy = '';

CREATE TABLE IF NOT EXISTS public.agent_session_summaries (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES public.tenants(id),
    agent_session_id uuid NOT NULL UNIQUE REFERENCES public.agent_sessions(id) ON DELETE CASCADE,
    source_history_version integer NOT NULL,
    summary_text text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
    updated_at timestamp with time zone NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS agent_session_summaries_tenant_session_idx
    ON public.agent_session_summaries (tenant_id, agent_session_id);
