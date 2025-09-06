import React, { useState, useEffect, useRef } from 'react';
import { supabase } from '../lib/supabase';
import { motion } from 'framer-motion';
import { Paperclip, Send, X, LogOut } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import AuthForm from './auth/AuthForm';

interface Conversation {
  id: string;
  created_at: string;
  status: string;
}
interface Message {
  id: string;
  content: string | null;
  media_url?: string;
  created_at: string;
  conversation_id: string;
  sender_id: string;
}

// Define types for our data
interface Message {
  id: number;
  content: string | null;
  media_url?: string;
  created_at: string;
  conversation_id: string;
  sender_id: string;
}

const Chat: React.FC = () => {
  const { user, signOut } = useAuth();
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [mediaFile, setMediaFile] = useState<File | null>(null);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [chatError, setChatError] = useState<string | null>(null);
  const messagesEndRef = useRef<null | HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages]);

  // Get or create conversation for the logged-in user
  useEffect(() => {
    if (user) {
      const initializeChat = async () => {
        // Check if the user is a participant in any conversation
        const { data: participant, error: participantError } = await supabase
          .from('participants')
          .select('conversation_id')
          .eq('user_id', user.id)
          .single();

        if (participantError && participantError.code !== 'PGRST116') {
          console.error('Error fetching participant:', participantError);
          setChatError("Erreur lors de la récupération de la conversation : " + participantError.message);
          return;
        }

        if (participant) {
          setConversationId(participant.conversation_id);
        } else {
          // If no conversation exists, create a new one et récupère l'id directement
          const { data: newConv, error: newConvError } = await supabase
            .from('conversations')
            .insert({})
            .select('id')
            .single();

          if (newConvError) {
            console.error('Error creating conversation:', newConvError);
            setChatError("Erreur lors de la création de la conversation : " + newConvError.message);
            return;
          }

          // Add the current user as a participant
          const { error: participantInsertError } = await supabase
            .from('participants')
            .insert({ conversation_id: newConv.id, user_id: user.id });

          if (participantInsertError) {
            console.error('Error adding participant:', participantInsertError);
            setChatError("Erreur lors de l'ajout du participant : " + participantInsertError.message);
          } else {
            setConversationId(newConv.id);
          }
        }
      };

      initializeChat();
    }
  }, [user]);

  // Fetch messages and subscribe to real-time updates
  useEffect(() => {
    if (conversationId) {
      const fetchMessages = async () => {
        const { data, error } = await supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', { ascending: true });

        if (error) {
          console.error('Error fetching messages:', error);
        } else {
          setMessages(data as Message[]);
        }
      };

      fetchMessages();

      // Gestion temps réel (realtime)
      const channel = supabase
        .channel(`realtime:messages:${conversationId}`)
        .on(
          'postgres_changes',
          { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${conversationId}` },
          (payload) => {
            setMessages((prev) => [...prev, payload.new as Message]);
          }
        )
        .subscribe();
      return () => { supabase.removeChannel(channel); };
    }
  }, [conversationId]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setMediaFile(e.target.files[0]);
    }
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if ((!newMessage.trim() && !mediaFile) || !conversationId || !user) return;

    // Debug log
    console.log('Sending message with:', { conversationId, userId: user.id });

    let media_url: string | undefined = undefined;

    if (mediaFile) {
      const fileExt = mediaFile.name.split('.').pop();
      const fileName = `${Date.now()}.${fileExt}`;
      const filePath = `chat/${conversationId}/${fileName}`;

      const { error: uploadError } = await supabase.storage.from('chat-media').upload(filePath, mediaFile);

      if (uploadError) {
        console.error('Error uploading file:', uploadError);
        return;
      }

      const { data } = supabase.storage.from('chat-media').getPublicUrl(filePath);
      media_url = data?.publicUrl;
    }

    const { error } = await supabase.from('messages').insert({
      content: newMessage || null,
      conversation_id: conversationId,
      sender_id: user.id,
      media_url: media_url,
    });

    if (error) {
      console.error('Error sending message:', error);
    } else {
      setNewMessage('');
      setMediaFile(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  // Affichage avatar simple (initiale de l'user)
  const renderAvatar = (msg: Message) => {
    if (msg.sender_id === user?.id) return null;
    return (
      <div className="w-8 h-8 rounded-full bg-gray-600 flex items-center justify-center text-white font-bold mr-2">
        {msg.sender_id?.slice(0, 2).toUpperCase()}
      </div>
    );
  };

  const renderMedia = (msg: Message) => {
    if (!msg.media_url) return null;
    const isImage = /\.(jpg|jpeg|png|gif)$/i.test(msg.media_url);
    const isVideo = /\.(mp4|webm|ogg)$/i.test(msg.media_url);
    if (isImage) return <img src={msg.media_url} alt="Media content" className="max-w-xs rounded-lg mt-2" />;
    if (isVideo) return <video src={msg.media_url} controls className="max-w-xs rounded-lg mt-2" />;
    return <a href={msg.media_url} target="_blank" rel="noopener noreferrer" className="text-gold hover:underline">View Media</a>;
  };
  
  if (!user) {
    return (
      <div className="max-w-lg mx-auto mt-12">
         <h2 className="text-3xl font-bold text-white text-center mb-6">Accéder au Chat</h2>
        <AuthForm />
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto bg-gray-900/50 backdrop-blur-md rounded-lg shadow-lg overflow-hidden" style={{ height: '70vh' }}>
        <div className="p-4 border-b border-gray-700 flex justify-between items-center">
            <h2 className="text-xl font-bold text-white text-center">Live Chat</h2>
            <button onClick={signOut} className="text-gray-300 hover:text-white transition-colors flex items-center">
              <LogOut size={18} className="mr-1.5" />
              Déconnexion
            </button>
        </div>
        <div className="messages-list flex-1 p-4 overflow-y-auto" style={{ height: 'calc(70vh - 140px)' }}>
      {messages.map((msg) => (
      <motion.div
        key={msg.id}
        initial={{ opacity: 0, y: 15 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
        className={`mb-4 flex ${msg.sender_id === user.id ? 'justify-end' : 'justify-start'}`}>
        {msg.sender_id !== user.id && renderAvatar(msg)}
        <div className={`p-3 rounded-lg max-w-xs lg:max-w-md ${msg.sender_id === user.id ? 'bg-gold text-black' : 'bg-gray-700 text-white'}`}>
          {msg.content && <p className="text-sm">{msg.content}</p>}
          {renderMedia(msg)}
          <span className="text-xs opacity-70 block text-right mt-1">
            {new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
          </span>
        </div>
      </motion.div>
      ))}
             <div ref={messagesEndRef} />
        </div>
        <div className="p-4 border-t border-gray-700">
            {chatError && (
              <div className="mb-2 text-red-500 text-sm font-semibold">{chatError}</div>
            )}
            <form onSubmit={handleSendMessage} className="flex items-center bg-gray-800 rounded-full px-1 py-1">
                <input
                type="text"
                value={newMessage}
                onChange={(e) => setNewMessage(e.target.value)}
                placeholder="Écrire un message..."
                className="flex-1 bg-transparent text-white px-4 py-2 focus:outline-none"
                />
                <input type="file" ref={fileInputRef} onChange={handleFileChange} className="hidden" id="client-file-upload" />
                <label htmlFor="client-file-upload" className="cursor-pointer p-2 rounded-full hover:bg-gray-700">
                  <Paperclip className="text-gray-400" />
                </label>
                <button
                  type="submit"
                  className="bg-gold text-black font-semibold rounded-full p-2.5 ml-1 hover:bg-yellow-400 transition-colors disabled:opacity-50"
                  disabled={!conversationId || !user || (!newMessage.trim() && !mediaFile)}
                >
                    <Send size={18}/>
                </button>
            </form>
            {mediaFile && (
              <div className="mt-2 flex items-center bg-gray-800 p-2 rounded-lg">
                <span className="text-sm text-gray-300 truncate flex-1 px-2">{mediaFile.name}</span>
                <button onClick={() => {setMediaFile(null); if(fileInputRef.current) fileInputRef.current.value = "";}} className="text-gray-400 hover:text-white">
                  <X size={16} />
                </button>
              </div>
            )}
        </div>
    </div>
  );
};

export default Chat;
