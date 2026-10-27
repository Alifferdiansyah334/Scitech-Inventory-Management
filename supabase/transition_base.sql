-- SIMS: additive transition for the existing Supabase profiles/items/loans.
-- No data is copied from Neon, seeded, deleted, or reassigned.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone text NOT NULL DEFAULT '';
ALTER TABLE public.items ADD COLUMN IF NOT EXISTS admin_id uuid REFERENCES public.profiles(user_id);
ALTER TABLE public.loans ADD COLUMN IF NOT EXISTS admin_image_id text;
ALTER TABLE public.loans ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE public.loans ADD COLUMN IF NOT EXISTS handed_over_at timestamptz;
ALTER TABLE public.loans ADD COLUMN IF NOT EXISTS return_requested_at timestamptz;
ALTER TABLE public.loans ADD COLUMN IF NOT EXISTS issue_note text;
DO $statuses$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace WHERE n.nspname='public' AND t.typname='loan_status') THEN
    ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'borrowed';
    ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'cancelled';
    ALTER TYPE public.loan_status ADD VALUE IF NOT EXISTS 'needs_review';
  ELSE
    ALTER TABLE public.loans DROP CONSTRAINT IF EXISTS loans_status_check;
    ALTER TABLE public.loans ADD CONSTRAINT loans_status_check CHECK (status IN ('pending','approved','borrowed','rejected','returned','overdue','returning','cancelled','needs_review'));
  END IF;
END $statuses$;

CREATE TABLE IF NOT EXISTS public.images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES public.profiles(user_id),
  bucket text NOT NULL CHECK (bucket IN ('item-images','return-images')),
  content_type text NOT NULL CHECK (content_type IN ('image/jpeg','image/png','image/webp')),
  data bytea NOT NULL CHECK (octet_length(data) <= 2097152),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.mobile_sessions (
  token_hash text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  provider_session_id text NOT NULL,
  encrypted_cookie text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.procurements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid NOT NULL REFERENCES public.items(id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  supplier text NOT NULL,
  unit_cost numeric(14,2) NOT NULL DEFAULT 0 CHECK (unit_cost >= 0),
  status text NOT NULL DEFAULT 'ordered' CHECK (status IN ('ordered','received','cancelled')),
  expected_at date, received_at timestamptz,
  created_by uuid NOT NULL REFERENCES public.profiles(user_id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS mobile_sessions_user_idx ON public.mobile_sessions(user_id);
CREATE INDEX IF NOT EXISTS procurements_item_idx ON public.procurements(item_id);
CREATE INDEX IF NOT EXISTS images_owner_idx ON public.images(owner_id);
CREATE INDEX IF NOT EXISTS items_admin_idx ON public.items(admin_id);
CREATE INDEX IF NOT EXISTS loans_admin_idx ON public.loans(admin_id);
CREATE INDEX IF NOT EXISTS loans_item_idx ON public.loans(item_id);
CREATE INDEX IF NOT EXISTS procurements_creator_idx ON public.procurements(created_by);
CREATE INDEX IF NOT EXISTS loans_borrower_created_idx ON public.loans(borrower_id, created_at DESC);
CREATE INDEX IF NOT EXISTS loans_status_created_idx ON public.loans(status, created_at DESC);
CREATE INDEX IF NOT EXISTS loans_borrow_date_idx ON public.loans(borrow_date);
CREATE INDEX IF NOT EXISTS items_created_idx ON public.items(created_at DESC);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mobile_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.procurements ENABLE ROW LEVEL SECURITY;
-- Server routes enforce ownership and roles. Direct browser writes could
-- otherwise bypass business transitions or change one's own role.
REVOKE ALL ON public.profiles, public.items, public.loans, public.images, public.mobile_sessions, public.procurements FROM anon, authenticated, PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles, public.items, public.loans, public.images, public.mobile_sessions, public.procurements TO service_role;

CREATE SCHEMA IF NOT EXISTS sims_private;
REVOKE ALL ON SCHEMA sims_private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA sims_private TO service_role;
CREATE TABLE IF NOT EXISTS sims_private.otp_challenges (
  email text NOT NULL, purpose text NOT NULL CHECK (purpose IN ('register','login','forgot_password')),
  user_id uuid, otp_hash text, expires_at timestamptz NOT NULL,
  sent_at timestamptz NOT NULL DEFAULT now(), attempts integer NOT NULL DEFAULT 0,
  window_start timestamptz NOT NULL DEFAULT now(), sends integer NOT NULL DEFAULT 1,
  PRIMARY KEY (email, purpose)
);
ALTER TABLE sims_private.otp_challenges ENABLE ROW LEVEL SECURITY;
DO $integrity$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='otp_challenges_auth_user_fk' AND conrelid='sims_private.otp_challenges'::regclass) THEN
    ALTER TABLE sims_private.otp_challenges ADD CONSTRAINT otp_challenges_auth_user_fk
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $integrity$;
CREATE INDEX IF NOT EXISTS otp_challenges_user_idx ON sims_private.otp_challenges(user_id);
REVOKE ALL ON sims_private.otp_challenges FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON sims_private.otp_challenges TO service_role;

CREATE OR REPLACE FUNCTION public.sims_issue_otp(p_email text, p_purpose text, p_hash text, p_user uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $fn$
DECLARE accepted text;
BEGIN
  INSERT INTO sims_private.otp_challenges AS c (email,purpose,user_id,otp_hash,expires_at)
  VALUES (p_email,p_purpose,p_user,p_hash,now()+interval '5 minutes')
  ON CONFLICT (email,purpose) DO UPDATE SET
    user_id=EXCLUDED.user_id, otp_hash=EXCLUDED.otp_hash, expires_at=EXCLUDED.expires_at,
    sent_at=now(), attempts=0,
    sends=CASE WHEN c.window_start < now()-interval '1 hour' THEN 1 ELSE c.sends+1 END,
    window_start=CASE WHEN c.window_start < now()-interval '1 hour' THEN now() ELSE c.window_start END
  WHERE c.sent_at < now()-interval '60 seconds'
    AND (c.window_start < now()-interval '1 hour' OR c.sends < 5)
  RETURNING email INTO accepted;
  RETURN accepted IS NOT NULL;
END $fn$;

CREATE OR REPLACE FUNCTION public.sims_check_otp(p_email text,p_purpose text,p_hash text,p_consume boolean)
RETURNS uuid LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $fn$
DECLARE c sims_private.otp_challenges%ROWTYPE;
BEGIN
  SELECT * INTO c FROM sims_private.otp_challenges WHERE email=p_email AND purpose=p_purpose FOR UPDATE;
  IF NOT FOUND OR c.expires_at <= now() OR c.attempts >= 5 OR c.otp_hash IS NULL THEN RETURN NULL; END IF;
  IF c.otp_hash <> p_hash OR c.user_id IS NULL THEN
    UPDATE sims_private.otp_challenges SET attempts=attempts+1 WHERE email=p_email AND purpose=p_purpose;
    RETURN NULL;
  END IF;
  IF p_consume THEN UPDATE sims_private.otp_challenges SET otp_hash=NULL WHERE email=p_email AND purpose=p_purpose; END IF;
  RETURN c.user_id;
END $fn$;
REVOKE ALL ON FUNCTION public.sims_issue_otp(text,text,text,uuid), public.sims_check_otp(text,text,text,boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sims_issue_otp(text,text,text,uuid), public.sims_check_otp(text,text,text,boolean) TO service_role;

CREATE TABLE IF NOT EXISTS sims_private.request_windows (
  key_hash text PRIMARY KEY, attempts integer NOT NULL DEFAULT 1,
  expires_at timestamptz NOT NULL
);
ALTER TABLE sims_private.request_windows ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sims_private.request_windows FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON sims_private.request_windows TO service_role;
CREATE OR REPLACE FUNCTION public.sims_rate_limit(p_key text, p_limit integer, p_seconds integer)
RETURNS boolean LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $fn$
DECLARE attempt_count integer;
BEGIN
  IF p_limit < 1 OR p_seconds < 1 THEN RETURN false; END IF;
  INSERT INTO sims_private.request_windows AS w (key_hash,expires_at)
  VALUES (p_key,now()+make_interval(secs=>p_seconds))
  ON CONFLICT (key_hash) DO UPDATE SET
    attempts=CASE WHEN w.expires_at<=now() THEN 1 ELSE w.attempts+1 END,
    expires_at=CASE WHEN w.expires_at<=now() THEN EXCLUDED.expires_at ELSE w.expires_at END
  RETURNING w.attempts INTO attempt_count;
  RETURN attempt_count<=p_limit;
END $fn$;
REVOKE ALL ON FUNCTION public.sims_rate_limit(text,integer,integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sims_rate_limit(text,integer,integer) TO service_role;
