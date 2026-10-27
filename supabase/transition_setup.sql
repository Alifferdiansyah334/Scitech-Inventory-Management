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

-- Generated by npm run db:prepare. Review and run this complete file.
CREATE OR REPLACE FUNCTION public.sims_query(query_id text, query_values jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path = 'public' AS $fn$
DECLARE parts jsonb; returns_rows boolean; statement text := ''; result jsonb := '[]'::jsonb; row_data record; i integer;
BEGIN
  CASE query_id
    -- lib/actions/loans.ts
    WHEN '0034995e402801fddbe432b467cb387376a8674b340e99f0cc852ad4b8baa9e2' THEN parts := '["\n      WITH returned AS (\n        UPDATE loans SET status = ''returned'', admin_id = ",",\n          admin_note = ",", actual_return_date = ","::timestamptz\n        WHERE id = ","::uuid AND status IN (''returning'',''needs_review'') RETURNING *\n      ), stock AS (\n        UPDATE items i SET quantity_available = i.quantity_available + r.quantity\n        FROM returned r WHERE i.id = r.item_id RETURNING i.id\n      ) SELECT r.* FROM returned r JOIN stock s ON s.id = r.item_id\n    "]'::jsonb; returns_rows := true;
    -- lib/actions/mobile-loans.ts
    WHEN '004fa083f018cd4bfd504a4ff8cc11e077ebb464a1019ea864923853e1e071ac' THEN parts := '["UPDATE loans SET status=''borrowed'', handed_over_at=now(), admin_id=",", admin_image_id=","\n      WHERE id=","::uuid AND status=''approved'' AND EXISTS (\n        SELECT 1 FROM images WHERE id::text="," AND owner_id="," AND bucket=''return-images'') RETURNING *"]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN '0734b068a15ce80181b87227cc66a87e483c5a164ab3667b96b090e5aba50737' THEN parts := '["\n        SELECT COALESCE(b.full_name, ''Unknown'') AS label, count(*)::int AS value\n        FROM loans l\n        JOIN profiles b ON b.user_id = l.borrower_id\n        GROUP BY b.full_name\n        ORDER BY value DESC\n        LIMIT 5\n      "]'::jsonb; returns_rows := true;
    -- app/api/admin/procurements/route.ts
    WHEN '11c24beba9c7af1882b52bd342421451766570ca6afa5184a88eb6ba43bb163f' THEN parts := '["WITH received AS (\n      UPDATE procurements SET status=",",received_at=CASE WHEN ","=''received'' THEN now() ELSE NULL END\n      WHERE id=","::uuid AND status=''ordered'' RETURNING *\n    ), stock AS (\n      UPDATE items i SET quantity_total=i.quantity_total+r.quantity,quantity_available=i.quantity_available+r.quantity\n      FROM received r WHERE i.id=r.item_id AND r.status=''received'' RETURNING i.id\n    ) SELECT * FROM received"]'::jsonb; returns_rows := true;
    -- lib/actions/loans.ts
    WHEN '18284a8a42f00ac4f3ef3f127d172bca0eaab13c4dc4a55b2a885c52b9517f26' THEN parts := '["\n      WITH target AS (\n        SELECT * FROM loans WHERE id = ","::uuid AND status = ''pending''\n        AND (","::text IS NULL OR EXISTS (\n          SELECT 1 FROM images WHERE id::text = "," AND owner_id = "," AND bucket = ''return-images''))\n        FOR UPDATE\n      ), stock AS (\n        UPDATE items i SET quantity_available = i.quantity_available - t.quantity\n        FROM target t WHERE i.id = t.item_id AND i.is_available AND i.quantity_available >= t.quantity\n        RETURNING i.id\n      )\n      UPDATE loans l SET status = ''approved'', approved_at = now(), admin_id = ",",\n        admin_note = ",", admin_image_id = ","\n      FROM target t, stock s WHERE l.id = t.id AND t.item_id = s.id RETURNING l.*\n    "]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN '18790baca9d65fa9e2aee82f2cfd00d4f959b5cd1d4b90c7ba2f618213a2ee5b' THEN parts := '["SELECT * FROM profiles ORDER BY created_at DESC"]'::jsonb; returns_rows := true;
    -- lib/actions/users.ts
    WHEN '1ed0641c89d0d3139d47e8d3ed38f6e0bc879cb743717eeed0783c283f7e650a' THEN parts := '["UPDATE profiles SET role = "," WHERE user_id = "," RETURNING user_id"]'::jsonb; returns_rows := true;
    -- lib/actions/loans.ts
    WHEN '2d3f8345cbe676dff1f80d1c0ab4f89ea10807fa3e2ed8d27f9bd1f55c3d6188' THEN parts := '["\n      INSERT INTO loans (item_id, borrower_id, quantity, purpose, borrow_date, return_date)\n      SELECT id, ",", ",", ",", ","::timestamptz, ","::timestamptz\n      FROM items WHERE id = ","::uuid AND is_available AND quantity_available >= ","\n      RETURNING *\n    "]'::jsonb; returns_rows := true;
    -- lib/actions/items.ts
    WHEN '38246c2acd16136b41f724088e0eeb2366a20ed3329df64742467dd4eff17f25' THEN parts := '["UPDATE items SET is_available = "," WHERE id = ","::uuid RETURNING *"]'::jsonb; returns_rows := true;
    -- lib/actions/mobile-loans.ts
    WHEN '4ade6f514bf6d422483207bf509136cb2050fbb497d3cf14ad99dd09ce2286d3' THEN parts := '["\n      WITH target AS (\n        SELECT * FROM loans\n        WHERE id=","::uuid AND ((borrower_id="," AND status=''pending'')\n          OR (","=''admin'' AND status IN (''pending'',''approved'')))\n        FOR UPDATE\n      ), cancelled AS (\n        UPDATE loans l SET status=''cancelled'', admin_note=","\n        FROM target t WHERE l.id=t.id\n        RETURNING l.*, t.status=''approved'' AS restore_stock\n      ), stock AS (\n        UPDATE items i SET quantity_available=i.quantity_available+c.quantity FROM cancelled c\n        WHERE i.id=c.item_id AND c.restore_stock RETURNING i.id\n      ) SELECT c.* FROM cancelled c\n    "]'::jsonb; returns_rows := true;
    -- lib/actions/items.ts
    WHEN '4de720bf5dc4ce6a22a1e6419369ce513c987abff52ee2d5c2e34c4bea466807' THEN parts := '["\n      INSERT INTO items (name, description, category, quantity_total, quantity_available, is_available, image_id, admin_id)\n      SELECT ",", ",", ",", ",", ",", ",", ",", ","\n      WHERE ","::text IS NULL OR EXISTS (\n        SELECT 1 FROM images WHERE id::text = "," AND owner_id = "," AND bucket = ''item-images'')\n      RETURNING *\n    "]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN '5024e36729cce1bdb00ca14ca3b95465f0a8b991db72cf4057713bead4d84079' THEN parts := '["SELECT * FROM items ORDER BY created_at DESC"]'::jsonb; returns_rows := true;
    -- lib/actions/users.ts
    WHEN '59139c52214b7a6a63263999bebbe03a04e19f03c482f3728a1a585e72507d1c' THEN parts := '["\n      UPDATE profiles SET full_name = ",",\n        department = ",",\n        phone = ",",\n        avatar_url = ","\n      WHERE user_id = "," RETURNING *\n    "]'::jsonb; returns_rows := true;
    -- app/api/images/[id]/route.ts
    WHEN '5a05ad9bb38883c9b0a216a40b6ef32318cdb6b28fdccc693fa68af828e0aaf0' THEN parts := '["\n    SELECT content_type, encode(data, ''base64'') AS content FROM images\n    WHERE id = ","::uuid AND (\n      bucket = ''item-images'' OR owner_id = "," OR "," = ''admin''\n      OR EXISTS (SELECT 1 FROM loans WHERE borrower_id = "," AND admin_image_id = ","))\n  "]'::jsonb; returns_rows := true;
    -- lib/actions/mobile-loans.ts
    WHEN '605354b9aa06777eb510556515586e01f7826a63456fb8ef920f3b0813d42729' THEN parts := '["UPDATE loans SET status=''needs_review'', issue_note=",", admin_id=","\n      WHERE id=","::uuid AND status=''returning'' RETURNING *"]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN '7160f32aa1286c5e6ac4f1f803eed1ca320a4f79c2f90b5ba089367e54025b26' THEN parts := '["SELECT * FROM items WHERE id = ","::uuid"]'::jsonb; returns_rows := true;
    -- lib/actions/loans.ts
    WHEN '788db0f739249f38297aefd02f667491eef386c60bc66d5731f54a7381d5a9f4' THEN parts := '["\n      UPDATE loans SET status = ''returning'', return_requested_at = now(), return_image_id = ",", user_note = ","\n      WHERE id = ","::uuid AND borrower_id = "," AND status IN (''borrowed'',''overdue'',''needs_review'')\n        AND EXISTS (SELECT 1 FROM images WHERE id::text = "," AND owner_id = "," AND bucket = ''return-images'')\n      RETURNING *\n    "]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN '82067d299653294f6e3c0b3fd7387f3e007d2b448f33dba1a271f08993deae08' THEN parts := '["\n        SELECT to_char(date_trunc(''month'', COALESCE(actual_return_date, return_date)), ''YYYY-MM'') AS month_key, count(*)::int AS count\n        FROM loans\n        WHERE status = ''returned'' AND COALESCE(actual_return_date, return_date) >= date_trunc(''month'', now() - interval ''5 months'')\n        GROUP BY date_trunc(''month'', COALESCE(actual_return_date, return_date))\n      "]'::jsonb; returns_rows := true;
    -- app/api/admin/procurements/route.ts
    WHEN '902cfa9678c00ffaa364337b16ce32edf746a3c82a39c7a45465f1419143dfb0' THEN parts := '["SELECT p.*, i.name AS item_name FROM procurements p JOIN items i ON i.id=p.item_id ORDER BY p.created_at DESC"]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN '9476ff5ef50e44fbfa1b5b6274ec443a9fd03032251dea13ce69ff1bd1b2802d' THEN parts := '["\n    SELECT l.*, row_to_json(i) AS item, row_to_json(b) AS borrower, row_to_json(a) AS admin\n    FROM loans l JOIN items i ON i.id = l.item_id\n    JOIN profiles b ON b.user_id = l.borrower_id\n    LEFT JOIN profiles a ON a.user_id = l.admin_id\n    WHERE (","::text IS NULL OR l.borrower_id = ",")\n    ORDER BY l.created_at DESC\n  "]'::jsonb; returns_rows := true;
    -- lib/actions/users.ts
    WHEN 'a266ec6b8df433981deaecd267f95edd901d153080de578c196af8e818402750' THEN parts := '["UPDATE profiles SET is_active = "," WHERE user_id = "," RETURNING user_id"]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN 'ab20d387d58528d96ba0e16a87fb41647b26b430d4cab61fe92212c07c9a710e' THEN parts := '["\n        SELECT l.*, row_to_json(i) AS item, row_to_json(b) AS borrower, row_to_json(a) AS admin\n        FROM loans l JOIN items i ON i.id = l.item_id\n        JOIN profiles b ON b.user_id = l.borrower_id\n        LEFT JOIN profiles a ON a.user_id = l.admin_id\n        ORDER BY l.created_at DESC\n        LIMIT 5\n      "]'::jsonb; returns_rows := true;
    -- lib/actions/loans.ts
    WHEN 'b55c5dae2a71ec834e6c31b7ac13da3d01d6e311f368f708d513243b4c3d3090' THEN parts := '["\n      UPDATE loans SET status = ''rejected'', admin_id = ",", admin_note = ","\n      WHERE id = ","::uuid AND status = ''pending'' RETURNING *\n    "]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN 'b966ae72faa6405f85750946e5cc56822955c8565dd602e935affef12acddc28' THEN parts := '["\n        SELECT status, count(*)::int AS count\n        FROM loans\n        GROUP BY status\n      "]'::jsonb; returns_rows := true;
    -- app/api/admin/procurements/route.ts
    WHEN 'c005e7549ec54f4b7af303958532bc2f36a28b95ace86963b16b250c912dbed3' THEN parts := '["INSERT INTO procurements(item_id,quantity,supplier,unit_cost,expected_at,created_by)\n      VALUES(","::uuid,",",",",",",","::date,",") RETURNING *"]'::jsonb; returns_rows := true;
    -- lib/actions/items.ts
    WHEN 'c3f803a03d62b7c40a0547019737f6afb7908d2fef3cec38e5d2c4cbcab58120' THEN parts := '["DELETE FROM items WHERE id = ","::uuid RETURNING id"]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN 'c4ab1269e71064c8d5288980ffc60fbafa2f6da4a2964addc26cfe030b152231' THEN parts := '["\n        SELECT COALESCE(b.full_name, ''Unknown'') AS label, count(*)::int AS value\n        FROM loans l\n        JOIN profiles b ON b.user_id = l.borrower_id\n        WHERE l.status = ''overdue'' OR (l.actual_return_date IS NOT NULL AND l.actual_return_date > l.return_date)\n        GROUP BY b.full_name\n        ORDER BY value DESC\n        LIMIT 5\n      "]'::jsonb; returns_rows := true;
    -- lib/backend/uploads.ts
    WHEN 'c4b3e4c795706d5a916832f6fec57fbe711658902040c9e3824c7301a02fb928' THEN parts := '["\n    INSERT INTO images (owner_id, bucket, content_type, data)\n    VALUES (",", ",", ",", decode(",", ''base64'')) RETURNING id\n  "]'::jsonb; returns_rows := true;
    -- lib/actions/items.ts
    WHEN 'c7978ec21e115985373dfc2e2ee84670529bc799760985bfd79240db08dbd16c' THEN parts := '["\n      UPDATE items SET name = ",", description = ",", category = ",",\n        quantity_total = ",", quantity_available = ",",\n        is_available = ",", image_id = ","\n      WHERE id = ","::uuid\n        AND ","::integer - ","::integer = quantity_total - quantity_available\n        AND (","::text IS NULL OR EXISTS (\n          SELECT 1 FROM images WHERE id::text = "," AND bucket = ''item-images''))\n      RETURNING *\n    "]'::jsonb; returns_rows := true;
    -- lib/backend/queries.ts
    WHEN 'cb7a6296f5856a8f79df4d9985e37dfa5fbd696ff63b0332564fbf730d89b266' THEN parts := '["\n        SELECT\n          (SELECT count(*)::int FROM items) AS total_items,\n          (SELECT count(*)::int FROM profiles) AS total_profiles,\n          (SELECT count(*)::int FROM loans WHERE status IN (''approved'',''borrowed'',''overdue'',''returning'',''needs_review'')) AS active_loans,\n          (SELECT count(*)::int FROM loans WHERE status = ''pending'') AS pending_loans\n      "]'::jsonb; returns_rows := true;
    -- lib/actions/loans.ts
    WHEN 'd62ed35ea390881e157f639196f54acb18a5e1d3032f4dd941a0e8552f4b7d12' THEN parts := '["DELETE FROM loans WHERE status IN (''pending'',''rejected'',''returned'')"]'::jsonb; returns_rows := false;
    -- lib/backend/queries.ts
    WHEN 'd6b41e96766b2424b0e1f1eefaa52a3fa30ba749867d8821d62c93c4cdd747d7' THEN parts := '["\n        SELECT to_char(date_trunc(''month'', borrow_date), ''YYYY-MM'') AS month_key, count(*)::int AS count\n        FROM loans\n        WHERE borrow_date >= date_trunc(''month'', now() - interval ''5 months'')\n        GROUP BY date_trunc(''month'', borrow_date)\n      "]'::jsonb; returns_rows := true;
    -- lib/actions/loans.ts
    WHEN 'e4442cfa234b0914eb0258d8109977f5e03b3f2a536bae93699baa051ec4dcb4' THEN parts := '["DELETE FROM loans WHERE id = ","::uuid AND status IN (''rejected'',''returned'',''cancelled'') RETURNING id"]'::jsonb; returns_rows := true;
    ELSE RAISE EXCEPTION 'Unknown application query';
  END CASE;
  IF jsonb_typeof(query_values) <> 'array' OR jsonb_array_length(query_values) <> jsonb_array_length(parts)-1 THEN
    RAISE EXCEPTION 'Invalid query parameters';
  END IF;
  FOR i IN 0..jsonb_array_length(parts)-1 LOOP
    statement := statement || (parts->>i);
    IF i < jsonb_array_length(query_values) THEN
      -- Quote each input once, independently; never replace text in a value.
      statement := statement || quote_nullable(query_values->>i);
    END IF;
  END LOOP;
  IF returns_rows THEN
    FOR row_data IN EXECUTE statement LOOP result := result || jsonb_build_array(to_jsonb(row_data)); END LOOP;
  ELSE EXECUTE statement;
  END IF;
  RETURN result;
END $fn$;
REVOKE ALL ON FUNCTION public.sims_query(text,jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.sims_query(text,jsonb) TO service_role;
NOTIFY pgrst, 'reload schema';
