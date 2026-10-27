-- Initial application tables for the dedicated sams Supabase project.
-- Supabase Auth owns credentials; application roles live only in profiles.
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL, email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'client' CHECK (role IN ('admin','client')),
  department text NOT NULL DEFAULT '', avatar_url text NOT NULL DEFAULT '',
  is_active boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL,
  description text NOT NULL DEFAULT '', category text NOT NULL,
  quantity_total integer NOT NULL DEFAULT 1 CHECK (quantity_total>=0),
  quantity_available integer NOT NULL DEFAULT 1 CHECK (quantity_available>=0 AND quantity_available<=quantity_total),
  image_id text, image_url text, is_available boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.loans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid NOT NULL REFERENCES public.items(id) ON DELETE RESTRICT,
  borrower_id uuid NOT NULL REFERENCES public.profiles(user_id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity>0), purpose text NOT NULL,
  borrow_date timestamptz NOT NULL, return_date timestamptz NOT NULL CHECK (return_date>=borrow_date),
  actual_return_date timestamptz,
  status text NOT NULL DEFAULT 'pending' CONSTRAINT loans_status_check
    CHECK (status IN ('pending','approved','borrowed','returning','returned','overdue','rejected','cancelled','needs_review')),
  admin_id uuid REFERENCES public.profiles(user_id), admin_note text,
  return_image_id text, return_image_url text, user_note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS items_created_at_idx ON public.items(created_at DESC);
CREATE INDEX IF NOT EXISTS loans_borrower_created_idx ON public.loans(borrower_id,created_at DESC);
CREATE INDEX IF NOT EXISTS loans_status_idx ON public.loans(status);
