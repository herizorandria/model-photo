-- 04_seed.sql
-- Données par défaut pour démarrer l'application

-- Catégories par défaut
INSERT INTO categories (name, name_fr, name_en, description, color) VALUES
  ('Fashion', 'Mode', 'Fashion', 'Fashion photography and editorial shoots', '#e91e63'),
  ('Portraits', 'Portraits', 'Portraits', 'Professional portrait photography', '#9c27b0'),
  ('Editorial', 'Éditorial', 'Editorial', 'Magazine and editorial photography', '#3f51b5'),
  ('Commercial', 'Commercial', 'Commercial', 'Brand campaigns and commercial work', '#00bcd4'),
  ('Beauty', 'Beauté', 'Beauty', 'Beauty and cosmetic photography', '#ff9800')
ON CONFLICT DO NOTHING;

-- Liens sociaux par défaut
INSERT INTO social_links (platform, url, icon, active, order_index) VALUES
  ('Instagram', 'https://instagram.com', 'Instagram', true, 1),
  ('TikTok', 'https://tiktok.com', 'Music', true, 2),
  ('Facebook', 'https://facebook.com', 'Facebook', true, 3),
  ('YouTube', 'https://youtube.com', 'Youtube', true, 4)
ON CONFLICT DO NOTHING;

-- Paramètres globaux par défaut (extraits principaux)
INSERT INTO settings (key, value) VALUES
  ('hero_title', 'Eva Moon'),
  ('hero_subtitle', 'Professional Model & Artist'),
  ('featured_title', 'Featured Photos'),
  ('gallery_title', 'Gallery'),
  ('social_title', 'Follow My Journey'),
  ('contact_title', 'Get In Touch'),
  ('about_text', 'Welcome to my professional portfolio.'),
  ('site_title', 'Eva Moon'),
  ('site_description', 'Professional model portfolio featuring fashion, portrait, and commercial photography.')
ON CONFLICT (key) DO NOTHING;

-- Paramètres geo_block_settings par défaut
INSERT INTO geo_block_settings (blocked_countries) VALUES ('{}') ON CONFLICT DO NOTHING;
