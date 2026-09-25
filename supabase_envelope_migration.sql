-- ====================================================================
-- Envelope Encryption Migration Script (Phase 1 Database Setup)
-- Script: supabase_envelope_migration.sql
-- Description: Additive schema updates, atomic lock/migration RPCs,
--              clock_timestamp() lease checks, immutable bundle staging,
--              idempotent retry reconciliation, tamper-proof CRUD fence,
--              and strict enc:v3: validation.
-- DO NOT EXECUTE IN PRODUCTION WITHOUT APPROVAL & REVIEW.
-- ====================================================================

-- 1. Additive columns for public.vault_settings (including wrapped_dek defensive check)
ALTER TABLE public.vault_settings
  ADD COLUMN IF NOT EXISTS wrapped_dek text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS pending_wrapped_dek text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS migration_status text NOT NULL DEFAULT 'not_started',
  ADD COLUMN IF NOT EXISTS migration_lock_id text DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS migration_lock_expires_at timestamptz DEFAULT NULL;

-- 2. Additive updated_at column for public.passwords (for optimistic concurrency)
ALTER TABLE public.passwords
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp();

-- 3. Index for migration status lookups
CREATE INDEX IF NOT EXISTS vault_settings_migration_status_idx 
  ON public.vault_settings (user_id, migration_status);

-- ====================================================================
-- TRIGGER FUNCTION: enforce_crud_migration_lock
-- Tamper-proof database fence on public.passwords.
-- Blocks all INSERT, DELETE, and non-ciphertext UPDATE operations
-- while migration_status is 'in_progress'. Validates lock ownership
-- and lease expiry for ciphertext migration updates.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.enforce_crud_migration_lock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_user_id pg_catalog.uuid;
  v_status text;
  v_lock_id text;
  v_expires_at timestamptz;
  v_active_lock text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_user_id := OLD.user_id;
  ELSE
    v_user_id := NEW.user_id;
  END IF;

  SELECT migration_status, migration_lock_id, migration_lock_expires_at
  INTO v_status, v_lock_id, v_expires_at
  FROM public.vault_settings
  WHERE user_id = v_user_id;

  -- If migration is not in progress, allow standard CRUD
  IF v_status IS NULL OR v_status <> 'in_progress' THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Migration IS in_progress: Block all INSERTS and DELETES unconditionally
  IF TG_OP = 'INSERT' OR TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'MIGRATION_IN_PROGRESS: Password creation and deletion are paused during vault migration.'
      USING ERRCODE = 'P0007';
  END IF;

  -- TG_OP == 'UPDATE': Verify internal RPC active lock context
  v_active_lock := pg_catalog.current_setting('pg_temp.active_migration_lock', true);

  -- Validate active lock token matches database lock and is unexpired
  IF v_active_lock IS NULL 
     OR v_lock_id IS NULL 
     OR v_active_lock <> v_lock_id 
     OR v_expires_at IS NULL 
     OR v_expires_at < pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'MIGRATION_IN_PROGRESS: Password updates are paused during active migration.'
      USING ERRCODE = 'P0007';
  END IF;

  -- Enforce ciphertext-only update bounds: Reject modifications to title, username, website, or notes
  IF NEW.title IS DISTINCT FROM OLD.title
     OR NEW.username IS DISTINCT FROM OLD.username
     OR NEW.website IS DISTINCT FROM OLD.website
     OR NEW.notes IS DISTINCT FROM OLD.notes THEN
    RAISE EXCEPTION 'MIGRATION_IN_PROGRESS: Password metadata fields cannot be edited during ciphertext migration.'
      USING ERRCODE = 'P0007';
  END IF;

  -- Enforce target ciphertext format
  IF NEW.password IS NULL OR NEW.password NOT LIKE 'enc:v3:%' THEN
    RAISE EXCEPTION 'MIGRATION_IN_PROGRESS: Password update during migration must be valid enc:v3: ciphertext.'
      USING ERRCODE = 'P0007';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS passwords_migration_crud_fence ON public.passwords;
CREATE TRIGGER passwords_migration_crud_fence
  BEFORE INSERT OR UPDATE OR DELETE ON public.passwords
  FOR EACH ROW EXECUTE FUNCTION public.enforce_crud_migration_lock();

-- ====================================================================
-- RPC FUNCTION 1: acquire_migration_lock
-- Atomically acquires a migration lock for the authenticated user.
-- Evaluates clock_timestamp() after FOR UPDATE lock acquisition.
-- Preserves existing salt, wrapped_dek, and verifier values.
-- Prevents restarting a completed migration.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.acquire_migration_lock(
  p_lock_id text,
  p_lease_seconds integer DEFAULT 900
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_user_id pg_catalog.uuid := auth.uid();
  v_settings RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: User must be authenticated to acquire migration lock.'
      USING ERRCODE = '42501';
  END IF;

  IF p_lock_id IS NULL OR pg_catalog.length(pg_catalog.trim(p_lock_id)) = 0 THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: p_lock_id cannot be null or empty.'
      USING ERRCODE = '22023';
  END IF;

  IF p_lease_seconds IS NULL OR p_lease_seconds < 10 OR p_lease_seconds > 3600 THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: p_lease_seconds must be between 10 and 3600 seconds.'
      USING ERRCODE = '22023';
  END IF;

  -- Ensure vault_settings row exists for auth.uid() without overwriting salt/verifier
  INSERT INTO public.vault_settings (user_id, salt, wrapped_dek, verifier, migration_status)
  VALUES (v_user_id, '', '', '', 'not_started')
  ON CONFLICT (user_id) DO NOTHING;

  -- Row-level FOR UPDATE lock
  SELECT migration_status, migration_lock_expires_at
  INTO v_settings
  FROM public.vault_settings
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_settings.migration_status = 'completed' THEN
    RETURN false;
  END IF;

  IF v_settings.migration_status = 'not_started' 
     OR (v_settings.migration_status = 'in_progress' AND (v_settings.migration_lock_expires_at IS NULL OR v_settings.migration_lock_expires_at < pg_catalog.clock_timestamp())) THEN
    
    UPDATE public.vault_settings
    SET 
      migration_lock_id = p_lock_id,
      migration_status = 'in_progress',
      migration_lock_expires_at = pg_catalog.clock_timestamp() + (p_lease_seconds || ' seconds')::pg_catalog.interval
    WHERE user_id = v_user_id;

    RETURN true;
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.acquire_migration_lock(text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.acquire_migration_lock(text, integer) TO authenticated;

-- ====================================================================
-- RPC FUNCTION 2: renew_migration_lock
-- Renews an existing migration lock for the authenticated user if valid.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.renew_migration_lock(
  p_lock_id text,
  p_lease_seconds integer DEFAULT 900
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_user_id pg_catalog.uuid := auth.uid();
  v_settings RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: User must be authenticated to renew migration lock.'
      USING ERRCODE = '42501';
  END IF;

  IF p_lease_seconds IS NULL OR p_lease_seconds < 10 OR p_lease_seconds > 3600 THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: p_lease_seconds must be between 10 and 3600 seconds.'
      USING ERRCODE = '22023';
  END IF;

  SELECT migration_lock_id, migration_status, migration_lock_expires_at
  INTO v_settings
  FROM public.vault_settings
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  IF v_settings.migration_status = 'in_progress'
     AND v_settings.migration_lock_id = p_lock_id
     AND v_settings.migration_lock_expires_at >= pg_catalog.clock_timestamp() THEN

    UPDATE public.vault_settings
    SET migration_lock_expires_at = pg_catalog.clock_timestamp() + (p_lease_seconds || ' seconds')::pg_catalog.interval
    WHERE user_id = v_user_id;

    RETURN true;
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.renew_migration_lock(text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.renew_migration_lock(text, integer) TO authenticated;

-- ====================================================================
-- RPC FUNCTION 3: stage_migration_bundle
-- Atomically stages the encrypted pending_wrapped_dek recovery bundle
-- and optional KDF salt.
-- EXPLICIT SALT SAFETY: Never overwrites an existing non-empty salt.
-- IMMUTABLE & IDEMPOTENT: Rejects replacing an existing different bundle.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.stage_migration_bundle(
  p_lock_id text,
  p_pending_wrapped_dek text,
  p_kdf_salt text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_user_id pg_catalog.uuid := auth.uid();
  v_settings RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: User must be authenticated to stage migration bundle.'
      USING ERRCODE = '42501';
  END IF;

  IF p_pending_wrapped_dek IS NULL OR pg_catalog.length(pg_catalog.trim(p_pending_wrapped_dek)) = 0 THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: p_pending_wrapped_dek cannot be null or empty.'
      USING ERRCODE = '22023';
  END IF;

  SELECT migration_lock_id, migration_status, migration_lock_expires_at, pending_wrapped_dek, salt
  INTO v_settings
  FROM public.vault_settings
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Vault settings row missing for user.'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_settings.migration_status <> 'in_progress'
     OR v_settings.migration_lock_id IS NULL
     OR v_settings.migration_lock_id <> p_lock_id
     OR v_settings.migration_lock_expires_at < pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'LOCK_EXPIRED_OR_STOLEN: Migration lock is no longer held by this session.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Immutability check: Allow idempotent re-staging of identical bundle, reject replacing with different bundle
  IF v_settings.pending_wrapped_dek IS NOT NULL AND pg_catalog.length(pg_catalog.trim(v_settings.pending_wrapped_dek)) > 0 THEN
    IF v_settings.pending_wrapped_dek <> p_pending_wrapped_dek THEN
      RAISE EXCEPTION 'BUNDLE_ALREADY_STAGED: Cannot overwrite an existing staged migration bundle with different content.'
        USING ERRCODE = 'P0005';
    END IF;
    -- Idempotent match
    RETURN true;
  END IF;

  -- Update pending bundle. Preserve existing salt if non-empty; set salt only if currently empty.
  UPDATE public.vault_settings
  SET 
    pending_wrapped_dek = p_pending_wrapped_dek,
    salt = CASE 
      WHEN (v_settings.salt IS NULL OR pg_catalog.length(pg_catalog.trim(v_settings.salt)) = 0) 
           AND p_kdf_salt IS NOT NULL AND pg_catalog.length(pg_catalog.trim(p_kdf_salt)) > 0 
      THEN p_kdf_salt 
      ELSE v_settings.salt 
    END,
    migration_lock_expires_at = pg_catalog.clock_timestamp() + pg_catalog.interval '15 minutes'
  WHERE user_id = v_user_id;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.stage_migration_bundle(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.stage_migration_bundle(text, text, text) TO authenticated;

-- ====================================================================
-- RPC FUNCTION 4: migrate_password_batch
-- CIPHERTEXT-ONLY MIGRATION BATCH: Modifies ONLY the password column.
-- Never touches title, username, website, or notes.
-- IDEMPOTENT RETRY RECONCILIATION: Accepts exact retries of committed rows.
-- Enforces enc:v3: prefix, duplicate ID rejection, and MANDATORY
-- expected_password optimistic concurrency validation.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.migrate_password_batch(
  p_lock_id text,
  p_updates jsonb
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_user_id pg_catalog.uuid := auth.uid();
  v_settings RECORD;
  v_item jsonb;
  v_item_id pg_catalog.uuid;
  v_new_password text;
  v_expected_password text;
  v_curr_password text;
  v_count integer := 0;
  v_rows_updated integer;
  v_batch_len integer;
  v_seen_ids pg_catalog.uuid[] := ARRAY[]::pg_catalog.uuid[];
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: User must be authenticated to execute batch migration.'
      USING ERRCODE = '42501';
  END IF;

  IF p_updates IS NULL OR pg_catalog.jsonb_typeof(p_updates) <> 'array' THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: p_updates must be a non-null JSON array.'
      USING ERRCODE = '22023';
  END IF;

  v_batch_len := pg_catalog.jsonb_array_length(p_updates);
  IF v_batch_len = 0 OR v_batch_len > 500 THEN
    RAISE EXCEPTION 'INVALID_ARGUMENT: Batch size must be between 1 and 500 records.'
      USING ERRCODE = '22023';
  END IF;

  -- Set session GUC lock token to allow trigger to permit internal migration updates
  PERFORM pg_catalog.set_config('pg_temp.active_migration_lock', p_lock_id, true);

  SELECT migration_lock_id, migration_status, migration_lock_expires_at, pending_wrapped_dek
  INTO v_settings
  FROM public.vault_settings
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Vault settings row missing for user.'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_settings.migration_status <> 'in_progress'
     OR v_settings.migration_lock_id IS NULL
     OR v_settings.migration_lock_id <> p_lock_id
     OR v_settings.migration_lock_expires_at < pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'LOCK_EXPIRED_OR_STOLEN: Migration lock is no longer held by this session.'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_settings.pending_wrapped_dek IS NULL OR pg_catalog.length(pg_catalog.trim(v_settings.pending_wrapped_dek)) = 0 THEN
    RAISE EXCEPTION 'UNSTAGED_MIGRATION: Cannot execute batch update before staging pending_wrapped_dek.'
      USING ERRCODE = 'P0003';
  END IF;

  -- Extend lock lease
  UPDATE public.vault_settings
  SET migration_lock_expires_at = pg_catalog.clock_timestamp() + pg_catalog.interval '15 minutes'
  WHERE user_id = v_user_id;

  -- Process ciphertext-only batch items
  FOR v_item IN SELECT * FROM pg_catalog.jsonb_array_elements(p_updates)
  LOOP
    IF v_item->>'id' IS NULL THEN
      RAISE EXCEPTION 'INVALID_ARGUMENT: Record missing required id field.'
        USING ERRCODE = '22023';
    END IF;

    BEGIN
      v_item_id := (v_item->>'id')::pg_catalog.uuid;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'INVALID_ARGUMENT: Invalid UUID format for id: %', v_item->>'id'
        USING ERRCODE = '22023';
    END;

    -- Reject duplicate record IDs in batch
    IF v_item_id = ANY(v_seen_ids) THEN
      RAISE EXCEPTION 'INVALID_ARGUMENT: Duplicate record ID % found in batch.', v_item_id
        USING ERRCODE = '22023';
    END IF;
    v_seen_ids := pg_catalog.array_append(v_seen_ids, v_item_id);

    v_new_password := v_item->>'password';
    IF v_new_password IS NULL OR v_new_password NOT LIKE 'enc:v3:%' THEN
      RAISE EXCEPTION 'INVALID_ARGUMENT: Password payload for record % must start with enc:v3:', v_item_id
        USING ERRCODE = '22023';
    END IF;

    v_expected_password := v_item->>'expected_password';
    IF v_expected_password IS NULL OR pg_catalog.length(pg_catalog.trim(v_expected_password)) = 0 THEN
      RAISE EXCEPTION 'INVALID_ARGUMENT: Record % missing required expected_password field for optimistic concurrency validation.', v_item_id
        USING ERRCODE = '22023';
    END IF;

    -- Fetch current password for row
    SELECT password INTO v_curr_password
    FROM public.passwords
    WHERE id = v_item_id AND user_id = v_user_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'RECORD_NOT_FOUND: Password record % does not exist or belong to user.', v_item_id
        USING ERRCODE = 'P0002';
    END IF;

    -- Idempotence Check: If row ALREADY matches v_new_password, exact retry after lost response!
    IF v_curr_password = v_new_password THEN
      v_count := v_count + 1;
      CONTINUE;
    END IF;

    -- Optimistic Concurrency Check: Require current password matches expected_password
    IF v_curr_password <> v_expected_password THEN
      RAISE EXCEPTION 'CONCURRENT_MODIFICATION: Record % was modified on another device or expected_password did not match.', v_item_id
        USING ERRCODE = 'P0006';
    END IF;

    -- STRICTLY CIPHERTEXT-ONLY UPDATE: Never modifies title, username, website, or notes
    UPDATE public.passwords
    SET 
      password = v_new_password,
      updated_at = pg_catalog.clock_timestamp()
    WHERE id = v_item_id
      AND user_id = v_user_id
      AND password = v_expected_password;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
    IF v_rows_updated = 0 THEN
      RAISE EXCEPTION 'CONCURRENT_MODIFICATION: Record % was modified on another device or expected_password did not match.', v_item_id
        USING ERRCODE = 'P0006';
    END IF;

    v_count := v_count + v_rows_updated;
  END LOOP;

  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.migrate_password_batch(text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.migrate_password_batch(text, jsonb) TO authenticated;

-- ====================================================================
-- RPC FUNCTION 5: complete_migration
-- Validates lock ownership, verifies no legacy ciphertext remains,
-- promotes pending_wrapped_dek to wrapped_dek, sets status to 'completed',
-- and clears the migration lock.
-- ====================================================================
CREATE OR REPLACE FUNCTION public.complete_migration(
  p_lock_id text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  v_user_id pg_catalog.uuid := auth.uid();
  v_settings RECORD;
  v_legacy_count integer := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: User must be authenticated to complete migration.'
      USING ERRCODE = '42501';
  END IF;

  SELECT migration_lock_id, migration_status, migration_lock_expires_at, pending_wrapped_dek
  INTO v_settings
  FROM public.vault_settings
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Vault settings row missing for user.'
      USING ERRCODE = 'P0002';
  END IF;

  IF v_settings.migration_status <> 'in_progress'
     OR v_settings.migration_lock_id IS NULL
     OR v_settings.migration_lock_id <> p_lock_id
     OR v_settings.migration_lock_expires_at < pg_catalog.clock_timestamp() THEN
    RAISE EXCEPTION 'LOCK_EXPIRED_OR_STOLEN: Migration lock is no longer held by this session.'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_settings.pending_wrapped_dek IS NULL OR pg_catalog.length(pg_catalog.trim(v_settings.pending_wrapped_dek)) = 0 THEN
    RAISE EXCEPTION 'UNSTAGED_MIGRATION: Cannot complete migration without staged pending_wrapped_dek.'
      USING ERRCODE = 'P0003';
  END IF;

  -- Audit: Ensure zero legacy records remain for auth.uid()
  SELECT pg_catalog.count(*)
  INTO v_legacy_count
  FROM public.passwords
  WHERE user_id = v_user_id
    AND (password NOT LIKE 'enc:v3:%');

  IF v_legacy_count > 0 THEN
    RAISE EXCEPTION 'INCOMPLETE_MIGRATION: % legacy records still remain in vault.', v_legacy_count
      USING ERRCODE = 'P0004';
  END IF;

  UPDATE public.vault_settings
  SET 
    wrapped_dek = v_settings.pending_wrapped_dek,
    pending_wrapped_dek = '',
    migration_status = 'completed',
    migration_lock_id = NULL,
    migration_lock_expires_at = NULL
  WHERE user_id = v_user_id;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.complete_migration(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_migration(text) TO authenticated;
