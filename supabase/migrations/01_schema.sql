-- 01_schema.sql
-- Création des tables principales, fonctions utilitaires et triggers

-- Fonction utilitaire pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Table categories
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  name_fr text NOT NULL,
  name_en text NOT NULL,
  description text,
  color text DEFAULT '#d4af37',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table photos
CREATE TABLE IF NOT EXISTS photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  image_url text NOT NULL,
  thumbnail_url text,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  tags text[] DEFAULT '{}',
  featured boolean DEFAULT false,
  views integer DEFAULT 0,
  clicks integer DEFAULT 0,
  shares integer DEFAULT 0,
  video_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table contact_messages
CREATE TABLE IF NOT EXISTS contact_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL,
  subject text NOT NULL,
  message text NOT NULL,
  status text DEFAULT 'unread' CHECK (status IN ('unread', 'read', 'replied')),
  ip_address text,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Table blocked_ips
CREATE TABLE IF NOT EXISTS blocked_ips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ip_address text NOT NULL UNIQUE,
  reason text,
  blocked_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Table social_links
CREATE TABLE IF NOT EXISTS social_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL,
  url text NOT NULL,
  icon text NOT NULL,
  active boolean DEFAULT true,
  order_index integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Table settings
CREATE TABLE IF NOT EXISTS settings (
  key text PRIMARY KEY,
  value text,
  updated_at timestamptz DEFAULT now()
);

-- Table hero_slides
CREATE TABLE IF NOT EXISTS hero_slides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url text NOT NULL,
  video_url text,
  title text NOT NULL,
  subtitle text NOT NULL,
  position integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Table url_clicks
CREATE TABLE IF NOT EXISTS url_clicks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ip text,
  device text,
  location_country text,
  location_city text,
  clicked_at timestamptz DEFAULT now()
);

-- Table geo_block_settings
CREATE TABLE IF NOT EXISTS geo_block_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocked_countries text[] DEFAULT '{}',
  updated_at timestamptz DEFAULT now()
);

-- Table geo_block_logs
CREATE TABLE IF NOT EXISTS geo_block_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code text,
  ip text,
  blocked_at timestamptz DEFAULT now()
);

-- Table conversations
CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  status text DEFAULT 'open'
);

-- Table participants
CREATE TABLE IF NOT EXISTS participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  UNIQUE (conversation_id, user_id)
);
-- Table profiles (public)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid NOT NULL PRIMARY KEY,
  email text,
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- Table messages
CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES profiles(id) ON DELETE CASCADE
);



-- Triggers for updated_at
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_photos_updated_at
  BEFORE UPDATE ON photos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_hero_slides_updated_at
  BEFORE UPDATE ON hero_slides
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_geo_block_settings_updated_at
  BEFORE UPDATE ON geo_block_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
