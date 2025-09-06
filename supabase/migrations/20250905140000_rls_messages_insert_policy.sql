-- Autoriser l'insertion de messages uniquement si l'utilisateur est participant à la conversation
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON messages;

CREATE POLICY "Users can send messages in their conversations" ON messages
FOR INSERT
TO authenticated
WITH CHECK (
  conversation_id IN (
    SELECT conversation_id FROM participants WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Users can insert messages in their conversations" ON messages
FOR INSERT
TO authenticated
WITH CHECK (
  conversation_id IN (
    SELECT conversation_id FROM participants WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Authenticated users can manage their conversations" ON conversations;

CREATE POLICY "Authenticated users can create conversations" ON conversations
FOR INSERT
TO authenticated
WITH CHECK (true);