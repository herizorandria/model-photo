-- 03_indexes.sql
-- Indexes pour optimiser les requêtes

-- Photos
CREATE INDEX IF NOT EXISTS idx_photos_category ON photos(category_id);
CREATE INDEX IF NOT EXISTS idx_photos_featured ON photos(featured) WHERE featured = true;
CREATE INDEX IF NOT EXISTS idx_photos_created ON photos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_photos_tags ON photos USING gin(tags);

-- Contact messages
CREATE INDEX IF NOT EXISTS idx_contact_messages_status ON contact_messages(status);
CREATE INDEX IF NOT EXISTS idx_contact_messages_created ON contact_messages(created_at DESC);

-- Social links
CREATE INDEX IF NOT EXISTS idx_social_links_active ON social_links(active, order_index) WHERE active = true;

-- Hero slides
CREATE INDEX IF NOT EXISTS idx_hero_slides_position ON hero_slides(position);

-- URL clicks
CREATE INDEX IF NOT EXISTS idx_url_clicks_clicked_at ON url_clicks(clicked_at DESC);
CREATE INDEX IF NOT EXISTS idx_url_clicks_country ON url_clicks(location_country);
CREATE INDEX IF NOT EXISTS idx_url_clicks_ip ON url_clicks(ip);

-- Geo block logs
CREATE INDEX IF NOT EXISTS idx_geo_block_logs_blocked_at ON geo_block_logs(blocked_at DESC);
CREATE INDEX IF NOT EXISTS idx_geo_block_logs_country ON geo_block_logs(country_code);

-- Participants
CREATE INDEX IF NOT EXISTS idx_participants_conversation ON participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_participants_user ON participants(user_id);

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
