-- Migration: Add password_hint column and RPC function
-- Run this in Supabase SQL Editor

-- 1. Add password_hint column to profiles table
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS password_hint TEXT;

-- 2. Create a public RPC function that returns the hint for a given email
--    SECURITY DEFINER allows it to bypass RLS (read-only, single column, no sensitive data)
CREATE OR REPLACE FUNCTION get_password_hint(user_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  hint TEXT;
BEGIN
  SELECT password_hint INTO hint
  FROM profiles
  WHERE email = user_email
  LIMIT 1;
  RETURN hint;
END;
$$;

-- 3. Grant execute permission to anonymous users (needed for pre-login access)
GRANT EXECUTE ON FUNCTION get_password_hint(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION get_password_hint(TEXT) TO authenticated;
