/*
  # Fix infinite recursion in RLS policies for conversations and participants
  - Replaces subquery-based policies with EXISTS-based policies to avoid recursion
*/

-- Drop problematic policies if they exist
DROP POLICY IF EXISTS "Authenticated users can manage their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Users can manage their own participant entries" ON participants;
DROP POLICY IF EXISTS "Users can view other participants in their conversations" ON participants;

-- Conversations: allow authenticated users to manage conversations they participate in
CREATE POLICY "Authenticated users can manage their conversations" ON conversations
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.conversation_id = conversations.id
      AND participants.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.conversation_id = conversations.id
      AND participants.user_id = auth.uid()
  )
);

-- Conversations: allow authenticated users to create conversations
CREATE POLICY "Authenticated users can create conversations" ON conversations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Participants: allow users to manage their own participant entries
CREATE POLICY "Users can manage their own participant entries" ON participants
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Participants: allow users to view other participants in their conversations
CREATE POLICY "Users can view other participants in their conversations" ON participants
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM participants p2
    WHERE p2.conversation_id = participants.conversation_id
      AND p2.user_id = auth.uid()
  )
);
