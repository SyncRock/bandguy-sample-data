-- Connect to kong database (run via Docker init script)
\connect kong

-- Create pgcrypto extension (needed for UUIDs)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Optional: create schema (Kong usually uses public)
-- CREATE SCHEMA IF NOT EXISTS kong;
