-- noa Database Schema
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/rougucdhmlzjopfzmdfp/sql

-- Prompts table - stores all user prompts and AI responses
CREATE TABLE IF NOT EXISTS prompts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT,
  text TEXT NOT NULL,
  response TEXT,
  screenshot_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries by user
CREATE INDEX IF NOT EXISTS prompts_user_id_idx ON prompts(user_id);

-- Index for device queries
CREATE INDEX IF NOT EXISTS prompts_device_id_idx ON prompts(device_id);

-- Index for ordering by date
CREATE INDEX IF NOT EXISTS prompts_created_at_idx ON prompts(created_at DESC);

-- Enable Row Level Security
ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own prompts (by user_id or device_id)
CREATE POLICY "Users can view own prompts" ON prompts
  FOR SELECT USING (
    auth.uid() = user_id OR 
    device_id IS NOT NULL
  );

-- Policy: Allow inserts from authenticated users
CREATE POLICY "Users can insert own prompts" ON prompts
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR 
    user_id IS NULL
  );

-- Policy: Allow service role to insert (for API)
CREATE POLICY "Service role can insert prompts" ON prompts
  FOR INSERT WITH CHECK (true);

-- Policy: Users can delete their own prompts
CREATE POLICY "Users can delete own prompts" ON prompts
  FOR DELETE USING (auth.uid() = user_id);

-- Migration: If table exists, add device_id column
-- ALTER TABLE prompts ADD COLUMN IF NOT EXISTS device_id TEXT;
-- ALTER TABLE prompts ALTER COLUMN user_id DROP NOT NULL;
