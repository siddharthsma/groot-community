ALTER TABLE agents
    ADD COLUMN IF NOT EXISTS skill_refs jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE agent_versions
    ADD COLUMN IF NOT EXISTS skill_refs jsonb NOT NULL DEFAULT '[]'::jsonb;

CREATE TABLE IF NOT EXISTS agent_skills (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text NOT NULL DEFAULT '',
    status text NOT NULL DEFAULT 'draft',
    instructions text NOT NULL DEFAULT '',
    resource_text text NOT NULL DEFAULT '',
    default_config jsonb NOT NULL DEFAULT '{}'::jsonb,
    recommended_tools jsonb NOT NULL DEFAULT '[]'::jsonb,
    active_version_number integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    updated_by_actor_type text,
    updated_by_actor_id text,
    updated_by_actor_email text,
    CONSTRAINT agent_skills_tenant_name_key UNIQUE (tenant_id, name)
);

CREATE TABLE IF NOT EXISTS agent_skill_versions (
    id uuid PRIMARY KEY,
    skill_id uuid NOT NULL REFERENCES agent_skills(id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    version_number integer NOT NULL,
    name text NOT NULL,
    description text NOT NULL DEFAULT '',
    instructions text NOT NULL DEFAULT '',
    resource_text text NOT NULL DEFAULT '',
    default_config jsonb NOT NULL DEFAULT '{}'::jsonb,
    recommended_tools jsonb NOT NULL DEFAULT '[]'::jsonb,
    is_active boolean NOT NULL DEFAULT false,
    activated_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    created_by_actor_type text,
    created_by_actor_id text,
    created_by_actor_email text,
    CONSTRAINT agent_skill_versions_skill_version_key UNIQUE (skill_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_agent_skills_tenant_id ON agent_skills (tenant_id);
CREATE INDEX IF NOT EXISTS idx_agent_skill_versions_skill_id ON agent_skill_versions (skill_id);
