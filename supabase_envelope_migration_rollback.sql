-- ====================================================================
-- Envelope Encryption Migration Rollback Script (Staging Only)
-- Script: supabase_envelope_migration_rollback.sql
-- Description: Safely drops RPC functions, trigger, index, and additive columns.
--
-- CAUTION / SAFETY WARNING:
-- This rollback script is safe to execute ONLY BEFORE migration staging
-- or record re-encryption begins. Do NOT execute if pending_wrapped_dek
-- has been staged or if password records have been converted to enc:v3:,
-- as dropping these columns without restoring legacy keys will cause
-- key material loss.
-- DO NOT EXECUTE IN PRODUCTION WITHOUT APPROVAL & REVIEW.
-- ====================================================================

-- 1. Drop trigger & function
DROP TRIGGER IF EXISTS passwords_migration_crud_fence ON public.passwords;
DROP FUNCTION IF EXISTS public.enforce_crud_migration_lock();

-- 2. Drop RPC functions
DROP FUNCTION IF EXISTS public.complete_migration(text);
DROP FUNCTION IF EXISTS public.migrate_password_batch(text, jsonb);
DROP FUNCTION IF EXISTS public.stage_migration_bundle(text, text, text);
DROP FUNCTION IF EXISTS public.stage_migration_bundle(text, text);
DROP FUNCTION IF EXISTS public.renew_migration_lock(text, integer);
DROP FUNCTION IF EXISTS public.acquire_migration_lock(text, integer);

-- 3. Drop migration index
DROP INDEX IF EXISTS public.vault_settings_migration_status_idx;

-- 4. Drop ONLY additive migration columns from vault_settings
-- Note: updated_at is intentionally preserved on public.passwords to avoid data loss.
ALTER TABLE public.vault_settings
  DROP COLUMN IF EXISTS migration_lock_expires_at,
  DROP COLUMN IF EXISTS migration_lock_id,
  DROP COLUMN IF EXISTS migration_status,
  DROP COLUMN IF EXISTS pending_wrapped_dek;
