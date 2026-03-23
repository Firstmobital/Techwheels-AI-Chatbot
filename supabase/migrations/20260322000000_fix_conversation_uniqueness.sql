-- Allow multiple conversations per phone number.
-- The old UNIQUE constraint on phone prevented returning customers from starting fresh.
-- We now use is_open to identify the active conversation.

ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_phone_key;

-- Add a partial unique index: only one open conversation per phone at a time.
CREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_phone_open
  ON public.conversations (phone)
  WHERE (is_open = true);

-- Update findOrCreateConversationByPhone logic note:
-- The Edge Function conversation-manager.ts uses upsert on phone with a unique constraint.
-- After this migration, the upsert must change to:
--   1. Try to find an existing OPEN conversation for this phone
--   2. If none exists, insert a new one (is_open = true)
-- This is handled in the next code change below.
