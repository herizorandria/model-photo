-- Simplification de la policy SELECT sur participants pour éviter toute récursion
DROP POLICY IF EXISTS "Users can view other participants in their conversations" ON participants;

CREATE POLICY "Users can view their participant entries" ON participants
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);
