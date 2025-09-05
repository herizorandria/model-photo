CREATE OR REPLACE FUNCTION get_user_conversation_ids()
RETURNS TABLE(conversation_id UUID)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT conversation_id FROM participants WHERE user_id = auth.uid();
$$;

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'open'
);

-- Create a table for public profile data
CREATE TABLE public.profiles (
  id UUID NOT NULL PRIMARY KEY,
  email TEXT,
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE
);

-- Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Allow public read access
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles
  FOR SELECT USING (true);

-- Allow users to manage their own profiles
CREATE POLICY "Users can insert their own profile." ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Function to create a profile for a new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute the function on new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Backfill existing users
INSERT INTO public.profiles (id, email)
SELECT id, email FROM auth.users
ON CONFLICT (id) DO NOTHING;

CREATE TABLE participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (conversation_id, user_id)
);

ALTER TABLE messages
ADD COLUMN conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
ADD COLUMN sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;


-- Enable Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Policies for conversations
CREATE POLICY "Authenticated users can manage their conversations" ON conversations
FOR ALL
TO authenticated
USING (
  id IN (SELECT get_user_conversation_ids.conversation_id FROM get_user_conversation_ids())
)
WITH CHECK (
    id IN (SELECT get_user_conversation_ids.conversation_id FROM get_user_conversation_ids())
);

CREATE POLICY "Authenticated users can create conversations" ON conversations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policies for participants
CREATE POLICY "Users can manage their own participant entries" ON participants
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view other participants in their conversations" ON participants
FOR SELECT
TO authenticated
USING ( 
    conversation_id IN (
        SELECT get_user_conversation_ids.conversation_id FROM get_user_conversation_ids()
    )
);


-- Policies for messages
CREATE POLICY "Users can view messages in their conversations" ON messages
FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT get_user_conversation_ids.conversation_id FROM get_user_conversation_ids()
    )
);

CREATE POLICY "Users can send messages in their conversations" ON messages
FOR INSERT
TO authenticated
WITH CHECK (
    conversation_id IN (
        SELECT get_user_conversation_ids.conversation_id FROM get_user_conversation_ids()
    )
);
