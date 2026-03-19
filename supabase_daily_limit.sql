-- Migration: Daily request limit enforcement + admin alerts
-- Run this in Supabase SQL Editor

-- 1. Create admin_alerts table
CREATE TABLE IF NOT EXISTS admin_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE admin_alerts ENABLE ROW LEVEL SECURITY;

-- 3. Admins can read and update (mark as read) all alerts
CREATE POLICY "Admins can read alerts" ON admin_alerts
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update alerts" ON admin_alerts
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- 4. Authenticated users can insert alerts (only with their own user_id)
CREATE POLICY "Users can insert own alerts" ON admin_alerts
  FOR INSERT WITH CHECK (auth.uid() = user_id);
