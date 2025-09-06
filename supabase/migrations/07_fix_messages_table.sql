-- 07_fix_messages_table.sql
-- Corrige la structure de la table messages pour le chat (supprime les colonnes inutiles, garde uniquement ce qui est nécessaire)

-- Renomme l'ancienne table pour backup
ALTER TABLE messages RENAME TO messages_old;

-- Crée la nouvelle table messages propre
CREATE TABLE messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    content text NOT NULL,
    created_at timestamptz DEFAULT now(),
    conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE
);

-- Copie les messages valides depuis l'ancienne table (si possible)
INSERT INTO messages (id, content, created_at, conversation_id, sender_id)
SELECT 
    gen_random_uuid(),  -- génère un nouvel id pour chaque message migré
    content, 
    created_at, 
    conversation_id, 
    sender_id
FROM messages_old
WHERE content IS NOT NULL AND conversation_id IS NOT NULL AND sender_id IS NOT NULL;

-- Supprime l'ancienne table
DROP TABLE messages_old;
