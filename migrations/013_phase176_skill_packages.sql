ALTER TABLE agent_skills
    ADD COLUMN IF NOT EXISTS reference_docs jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS assets jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE agent_skill_versions
    ADD COLUMN IF NOT EXISTS reference_docs jsonb NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS assets jsonb NOT NULL DEFAULT '[]'::jsonb;
