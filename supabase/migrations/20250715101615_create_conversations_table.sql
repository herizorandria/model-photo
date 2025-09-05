
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (conversation_id, user_id)
);

ALTER TABLE messages
ADD COLUMN conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Enable Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;

-- Policies for conversations
CREATE POLICY "Authenticated users can view their conversations" ON conversations
FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT conversation_id FROM participants WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Authenticated users can create conversations" ON conversations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policies for participants
-- Drop old policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Authenticated users can view participants of their conversations" ON participants;
DROP POLICY IF EXISTS "Authenticated users can add participants to their conversations" ON participants;
DROP POLICY IF EXISTS "Authenticated users can add themselves as participants" ON participants;

-- A user can see and manage their own participant record.
CREATE POLICY "Users can manage their own participant entries" ON participants
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Allow users to see other participants in conversations they are a part of.
CREATE POLICY "Users can view other participants in their conversations" ON participants
FOR SELECT
TO authenticated
USING ( conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid()) );
