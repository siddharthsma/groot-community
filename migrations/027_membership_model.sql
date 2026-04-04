CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_identities (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider_type TEXT NOT NULL,
  issuer TEXT,
  external_subject TEXT NOT NULL,
  email TEXT NOT NULL DEFAULT '',
  display_name TEXT NOT NULL DEFAULT '',
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS user_identities_provider_subject_uq
ON user_identities(provider_type, COALESCE(issuer, ''), external_subject);

CREATE UNIQUE INDEX IF NOT EXISTS user_identities_primary_per_user_uq
ON user_identities(user_id)
WHERE is_primary = TRUE;

CREATE TABLE IF NOT EXISTS password_credentials (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  password_hash TEXT NOT NULL,
  password_updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tenant_memberships (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
  invited_by_user_id UUID REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, user_id),
  CONSTRAINT tenant_memberships_role_check CHECK (role IN ('owner', 'admin', 'member')),
  CONSTRAINT tenant_memberships_status_check CHECK (status IN ('active', 'suspended'))
);

CREATE INDEX IF NOT EXISTS tenant_memberships_tenant_idx
ON tenant_memberships(tenant_id, status);

CREATE INDEX IF NOT EXISTS tenant_memberships_user_idx
ON tenant_memberships(user_id, status);

CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  active_tenant_id UUID NOT NULL REFERENCES tenants(id),
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMP NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS user_sessions_user_idx
ON user_sessions(user_id, revoked_at, expires_at);

CREATE TABLE IF NOT EXISTS tenant_invitations (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending',
  expires_at TIMESTAMP NOT NULL,
  accepted_by_user_id UUID REFERENCES users(id),
  created_by_user_id UUID REFERENCES users(id),
  accepted_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT tenant_invitations_role_check CHECK (role IN ('owner', 'admin', 'member')),
  CONSTRAINT tenant_invitations_status_check CHECK (status IN ('pending', 'accepted', 'revoked', 'expired'))
);

CREATE INDEX IF NOT EXISTS tenant_invitations_tenant_idx
ON tenant_invitations(tenant_id, status);

CREATE INDEX IF NOT EXISTS tenant_invitations_email_idx
ON tenant_invitations(email, status);

ALTER TABLE audit_events
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS membership_id UUID REFERENCES tenant_memberships(id),
ADD COLUMN IF NOT EXISTS principal_kind TEXT;

CREATE INDEX IF NOT EXISTS audit_events_user_created_idx
ON audit_events(user_id, created_at);
