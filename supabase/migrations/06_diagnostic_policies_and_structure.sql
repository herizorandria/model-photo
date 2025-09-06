-- 06_diagnostic_policies_and_structure.sql
-- Liste toutes les policies actives et la structure des tables critiques

-- Liste des policies sur conversations, participants, messages
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check FROM pg_policies WHERE tablename IN ('conversations', 'participants', 'messages');

-- Structure de la table participants
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'participants';

-- Structure de la table conversations
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'conversations';

-- Structure de la table messages
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'messages';
