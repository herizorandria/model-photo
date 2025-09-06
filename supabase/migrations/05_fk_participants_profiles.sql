-- 05_fk_participants_profiles.sql
-- Ajoute la contrainte de clé étrangère manquante pour permettre les jointures imbriquées Supabase/PostgREST

ALTER TABLE participants
ADD CONSTRAINT participants_user_id_fkey FOREIGN KEY (user_id)
REFERENCES public.profiles(id) ON DELETE CASCADE;
