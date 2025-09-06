-- Correction des policies RLS sur conversations pour éviter le blocage à l'insertion
DROP POLICY IF EXISTS "Authenticated users can manage their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;


-- Policy SELECT : accès seulement si participant
CREATE POLICY "Authenticated users can select their conversations" ON conversations
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.conversation_id = conversations.id
      AND participants.user_id = auth.uid()
  )
);

-- Policy UPDATE : accès seulement si participant
CREATE POLICY "Authenticated users can update their conversations" ON conversations
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.conversation_id = conversations.id
      AND participants.user_id = auth.uid()
  )
);

-- Policy DELETE : accès seulement si participant
CREATE POLICY "Authenticated users can delete their conversations" ON conversations
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.conversation_id = conversations.id
      AND participants.user_id = auth.uid()
  )
);

-- Policy INSERT : tout authentifié peut créer
CREATE POLICY "Authenticated users can create conversations" ON conversations
FOR INSERT
TO authenticated
WITH CHECK (true);
