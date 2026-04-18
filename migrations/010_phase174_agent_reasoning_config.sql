ALTER TABLE public.agents
    ADD COLUMN IF NOT EXISTS reasoning_config jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.agent_versions
    ADD COLUMN IF NOT EXISTS reasoning_config jsonb NOT NULL DEFAULT '{}'::jsonb;
