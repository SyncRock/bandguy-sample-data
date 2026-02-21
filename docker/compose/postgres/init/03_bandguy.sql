-- Connect to bandguy database
\connect bandguy

-- 
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- for UUID generation

-- Create a new schema
CREATE SCHEMA IF NOT EXISTS bandguy;


-- Set the search path to the new schema
SET search_path TO bandguy, public;

CREATE TABLE bandguy.app_users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    display_name        TEXT NOT NULL,
    email               TEXT NOT NULL,

    email_verified      BOOLEAN NOT NULL DEFAULT FALSE,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    is_disabled         BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX uq_app_users_email ON app_users (LOWER(email));

CREATE TABLE user_auth_providers (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id                 UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,

    provider_name           TEXT NOT NULL, 
    -- e.g. 'google', 'facebook', 'github', 'microsoft'

    provider_user_id        TEXT NOT NULL,
    -- the unique user ID returned by the provider

    provider_email          TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (provider_name, provider_user_id)
);

CREATE INDEX idx_user_auth_user_id ON user_auth_providers (user_id);

CREATE TABLE user_file_sets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    owner_id        UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,

    file_name       TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,

    UNIQUE (owner_id, file_name)
);

CREATE INDEX idx_user_file_sets_owner ON user_file_sets (owner_id);

CREATE TABLE user_file_versions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    file_set_id         UUID NOT NULL 
                        REFERENCES user_file_sets(id) ON DELETE CASCADE,

    version_number      INTEGER NOT NULL,

    file_location       TEXT NOT NULL,
    -- e.g. s3://bucket/key

    file_size_bytes     BIGINT,
    content_type        TEXT,
    checksum_sha256     TEXT,

    uploaded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (file_set_id, version_number)
);

CREATE INDEX idx_file_versions_lookup ON user_file_versions (file_set_id, version_number DESC);
