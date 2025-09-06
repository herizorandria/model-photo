-- 08_fix_participants_and_conversations_policies.sql
-- Corrige les policies pour participants et conversations (chat)

-- Supprime les policies existantes trop restrictives ou conflictuelles
DROP POLICY IF EXISTS "Users can view other participants in their conversations" ON participants;
DROP POLICY IF EXISTS "Users can manage their own participant entries" ON participants;
DROP POLICY IF EXISTS "Users can select their participant entries" ON participants;

DROP POLICY IF EXISTS "Authenticated users can manage their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can select their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can update their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can delete their conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;

-- Policy SELECT participants : accès à ses propres entrées
CREATE POLICY "Users can select their participant entries" ON participants
FOR SELECT TO authenticated
USING (auth.uid() = user_id);

-- Policy ALL participants : gestion de ses propres entrées
CREATE POLICY "Users can manage their own participant entries" ON participants
FOR ALL TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy INSERT conversations : tout authentifié peut créer
CREATE POLICY "Authenticated users can create conversations" ON conversations
FOR INSERT TO authenticated
WITH CHECK (true);

-- Policy SELECT conversations : accès seulement si participant
CREATE POLICY "Authenticated users can select their conversations" ON conversations
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM participants
    WHERE participants.conversation_id = conversations.id
      AND participants.user_id = auth.uid()
  )
);
