-- Add tools_used column to prompts table
-- This tracks which tools/integrations were used for each prompt (calendar, gmail, etc.)

ALTER TABLE prompts
ADD COLUMN IF NOT EXISTS tools_used TEXT[] DEFAULT NULL;

-- Add a comment for documentation
COMMENT ON COLUMN prompts.tools_used IS 'Array of tools used for this prompt (calendar_create, calendar_delete, calendar_query, gmail_query)';

-- Create an index for filtering by tool usage (optional, for analytics)
CREATE INDEX IF NOT EXISTS idx_prompts_tools_used ON prompts USING GIN (tools_used);
