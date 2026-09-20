-- Create custom types
CREATE TYPE user_role AS ENUM ('admin', 'client');
CREATE TYPE loan_status AS ENUM ('pending', 'approved', 'rejected', 'returned', 'overdue', 'returning');

-- PROFILES
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role user_role DEFAULT 'client',
  department TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true
);

-- Index for fast user lookups
CREATE INDEX profiles_user_id_idx ON profiles(user_id);
CREATE INDEX profiles_email_idx ON profiles(email);
CREATE INDEX profiles_role_idx ON profiles(role);

-- ITEMS
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  quantity_total INTEGER NOT NULL DEFAULT 1,
  quantity_available INTEGER NOT NULL DEFAULT 1,
  image_id TEXT,
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX items_category_idx ON items(category);
CREATE INDEX items_available_idx ON items(is_available);
CREATE INDEX items_created_at_idx ON items(created_at);

-- LOANS
CREATE TABLE loans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID REFERENCES items(id) ON DELETE RESTRICT,
  borrower_id UUID REFERENCES profiles(user_id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL DEFAULT 1,
  purpose TEXT NOT NULL,
  borrow_date TIMESTAMPTZ NOT NULL,
  return_date TIMESTAMPTZ NOT NULL,
  actual_return_date TIMESTAMPTZ,
  status loan_status DEFAULT 'pending',
  admin_id UUID REFERENCES profiles(user_id) ON DELETE SET NULL,
  admin_note TEXT,
  return_image_id TEXT,
  return_image_url TEXT,
  user_note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX loans_status_idx ON loans(status);
CREATE INDEX loans_borrower_idx ON loans(borrower_id);
CREATE INDEX loans_item_idx ON loans(item_id);

-- RLS (Row Level Security)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON profiles FOR INSERT WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING ((select auth.uid()) = user_id);
-- Admins can do everything on profiles
CREATE POLICY "Admins have full access to profiles" ON profiles FOR ALL USING (
  (SELECT role FROM profiles WHERE user_id = auth.uid()) = 'admin'
);

-- Items Policies
CREATE POLICY "Items are viewable by everyone." ON items FOR SELECT USING (true);
CREATE POLICY "Admins have full access to items." ON items FOR ALL USING (
  (SELECT role FROM profiles WHERE user_id = auth.uid()) = 'admin'
);

-- Loans Policies
CREATE POLICY "Users can view their own loans." ON loans FOR SELECT USING (
  (select auth.uid()) = borrower_id OR 
  (SELECT role FROM profiles WHERE user_id = auth.uid()) = 'admin'
);
CREATE POLICY "Users can insert their own loans." ON loans FOR INSERT WITH CHECK (
  (select auth.uid()) = borrower_id
);
CREATE POLICY "Users can update their own loans." ON loans FOR UPDATE USING (
  (select auth.uid()) = borrower_id OR 
  (SELECT role FROM profiles WHERE user_id = auth.uid()) = 'admin'
);
CREATE POLICY "Admins have full access to loans." ON loans FOR ALL USING (
  (SELECT role FROM profiles WHERE user_id = auth.uid()) = 'admin'
);

-- Set up Realtime
alter publication supabase_realtime add table profiles;
alter publication supabase_realtime add table items;
alter publication supabase_realtime add table loans;

-- Storage buckets
-- Requires supabase storage api to be enabled
INSERT INTO storage.buckets (id, name, public) VALUES ('item-images', 'item-images', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('return-images', 'return-images', true) ON CONFLICT DO NOTHING;
