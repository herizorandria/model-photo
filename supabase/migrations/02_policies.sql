-- 02_policies.sql
-- Activation RLS et policies pour toutes les tables

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_ips ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE hero_slides ENABLE ROW LEVEL SECURITY;
ALTER TABLE url_clicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE geo_block_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE geo_block_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Categories
CREATE POLICY "Categories are viewable by everyone" ON categories FOR SELECT TO public USING (true);
CREATE POLICY "Categories are manageable by authenticated users" ON categories FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Photos
CREATE POLICY "Photos are viewable by everyone" ON photos FOR SELECT TO public USING (true);
CREATE POLICY "Photos are manageable by authenticated users" ON photos FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Contact messages
CREATE POLICY "Contact messages are insertable by everyone" ON contact_messages FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Contact messages are viewable by authenticated users" ON contact_messages FOR SELECT TO authenticated USING (true);
CREATE POLICY "Contact messages are manageable by authenticated users" ON contact_messages FOR UPDATE TO authenticated USING (true);

-- Blocked IPs
CREATE POLICY "Blocked IPs are viewable by authenticated users" ON blocked_ips FOR SELECT TO authenticated USING (true);
CREATE POLICY "Blocked IPs are manageable by authenticated users" ON blocked_ips FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Social links
CREATE POLICY "Social links are viewable by everyone" ON social_links FOR SELECT TO public USING (true);
CREATE POLICY "Social links are manageable by authenticated users" ON social_links FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Settings
CREATE POLICY "Settings are viewable by everyone" ON settings FOR SELECT TO public USING (true);
CREATE POLICY "Settings are manageable by authenticated users" ON settings FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Hero slides
CREATE POLICY "Hero slides are viewable by everyone" ON hero_slides FOR SELECT TO public USING (true);
CREATE POLICY "Hero slides are manageable by authenticated users" ON hero_slides FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- URL clicks
CREATE POLICY "URL clicks are insertable by everyone" ON url_clicks FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "URL clicks are viewable by authenticated users" ON url_clicks FOR SELECT TO authenticated USING (true);

-- Geo block settings
CREATE POLICY "Geo block settings are viewable by everyone" ON geo_block_settings FOR SELECT TO public USING (true);
CREATE POLICY "Geo block settings are manageable by authenticated users" ON geo_block_settings FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Geo block logs
CREATE POLICY "Geo block logs are insertable by everyone" ON geo_block_logs FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Geo block logs are viewable by authenticated users" ON geo_block_logs FOR SELECT TO authenticated USING (true);

-- Conversations
CREATE POLICY "Authenticated users can select their conversations" ON conversations FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM participants WHERE participants.conversation_id = conversations.id AND participants.user_id = auth.uid())
);
CREATE POLICY "Authenticated users can update their conversations" ON conversations FOR UPDATE TO authenticated USING (
  EXISTS (SELECT 1 FROM participants WHERE participants.conversation_id = conversations.id AND participants.user_id = auth.uid())
);
CREATE POLICY "Authenticated users can delete their conversations" ON conversations FOR DELETE TO authenticated USING (
  EXISTS (SELECT 1 FROM participants WHERE participants.conversation_id = conversations.id AND participants.user_id = auth.uid())
);
CREATE POLICY "Authenticated users can create conversations" ON conversations FOR INSERT TO authenticated WITH CHECK (true);

-- Participants
CREATE POLICY "Users can select their participant entries" ON participants FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own participant entries" ON participants FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Messages
CREATE POLICY "Users can select messages in their conversations" ON messages FOR SELECT TO authenticated USING (
  conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid())
);
CREATE POLICY "Users can insert messages in their conversations" ON messages FOR INSERT TO authenticated WITH CHECK (
  conversation_id IN (SELECT conversation_id FROM participants WHERE user_id = auth.uid())
);

-- Profiles
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT TO public USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
