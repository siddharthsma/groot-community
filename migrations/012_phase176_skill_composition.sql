ALTER TABLE agent_skills
    ADD COLUMN IF NOT EXISTS required_tools jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS required_integrations jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS supported_event_types jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS requires_session_context boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS requires_wait_tools boolean NOT NULL DEFAULT false;

ALTER TABLE agent_skill_versions
    ADD COLUMN IF NOT EXISTS required_tools jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS required_integrations jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS supported_event_types jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS requires_session_context boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS requires_wait_tools boolean NOT NULL DEFAULT false;
