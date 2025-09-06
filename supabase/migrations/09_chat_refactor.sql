
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS participants CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;

CREATE TABLE conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  status text DEFAULT 'open'
);

CREATE TABLE participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (conversation_id, user_id)
);

CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_participants_conversation ON participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_participants_user ON participants(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Authenticated users can select their conversations" ON conversations;
CREATE POLICY "Authenticated users can create conversations" ON conversations
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can select their conversations" ON conversations
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM participants WHERE participants.conversation_id = conversations.id AND participants.user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can select their participant entries" ON participants;
DROP POLICY IF EXISTS "Users can manage their own participant entries" ON participants;
CREATE POLICY "Users can select their participant entries" ON participants
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own participant entries" ON participants
  FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can select messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can insert messages in their conversations" ON messages;
CREATE POLICY "Users can select messages in their conversations" ON messages
  FOR SELECT TO authenticated
  USING (conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid()));
CREATE POLICY "Users can insert messages in their conversations" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid()));
