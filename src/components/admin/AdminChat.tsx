import React, { useState, useEffect, useRef } from 'react';
import { supabase } from '../../lib/supabase';
import { motion } from 'framer-motion';
import { Paperclip, Send, X } from 'lucide-react';

// Define types for our data
interface Conversation {
  id: string;
  user_id: string;
  created_at: string;
  status: 'open' | 'closed';
  users: {
    email: string;
  } | null;
}

interface Message {
  id: number;
  content: string | null; // Content can be null
  media_url?: string; // Media URL is optional
  created_at: string;
  conversation_id: string;
  sender_id: string;
}

const AdminChat: React.FC = () => {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [mediaFile, setMediaFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(true);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Fetch all conversations with user emails
  useEffect(() => {
    const fetchConversations = async () => {
      setLoading(true);
      const { data, error } = await supabase
        .from('conversations')
        .select('*, users(email)') // Join with users table to get email
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching conversations:', error);
      } else {
        setConversations(data as any[] as Conversation[]);
      }
      setLoading(false);
    };

    fetchConversations();
  }, []);

  // Fetch messages for the selected conversation
  useEffect(() => {
    if (selectedConversation) {
      const fetchMessages = async () => {
        const { data, error } = await supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', selectedConversation.id)
          .order('created_at', { ascending: true });

        if (error) {
          console.error('Error fetching messages:', error);
        } else {
          setMessages(data as Message[]);
        }
      };

      fetchMessages();

      // Subscribe to new messages
      const messageSubscription = supabase
        .channel(`messages:${selectedConversation.id}`)
        .on(
          'postgres_changes',
          { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${selectedConversation.id}` },
          (payload) => {
            setMessages((prevMessages) => [...prevMessages, payload.new as Message]);
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(messageSubscription);
      };
    }
  }, [selectedConversation]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setMediaFile(e.target.files[0]);
    }
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if ((!newMessage.trim() && !mediaFile) || !selectedConversation) return;

    const moderatorId = 'moderator'; // Admin sender ID remains constant
    let media_url: string | undefined = undefined;

    if (mediaFile) {
      const fileExt = mediaFile.name.split('.').pop();
      const fileName = `${Date.now()}.${fileExt}`;
      const filePath = `chat/${selectedConversation.id}/${fileName}`;

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
      conversation_id: selectedConversation.id,
      sender_id: moderatorId,
      media_url: media_url,
    });

    if (error) {
      console.error('Error sending message:', error);
    } else {
      setNewMessage('');
      setMediaFile(null);
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };
  
  const renderMedia = (msg: Message) => {
    if (!msg.media_url) return null;
    
    const isImage = /\.(jpg|jpeg|png|gif)$/i.test(msg.media_url);
    const isVideo = /\.(mp4|webm|ogg)$/i.test(msg.media_url);

    if (isImage) {
      return <img src={msg.media_url} alt="Media content" className="max-w-xs rounded-lg mt-2" />;
    } else if (isVideo) {
      return <video src={msg.media_url} controls className="max-w-xs rounded-lg mt-2" />;
    } else {
      return <a href={msg.media_url} target="_blank" rel="noopener noreferrer" className="text-gold hover:underline">View Media</a>;
    }
  }

  if (loading) {
    return <div className="text-white p-8">Loading conversations...</div>;
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] bg-gray-900 text-white">
      {/* Conversations List */}
      <div className="w-1/3 border-r border-gray-700 overflow-y-auto">
        <h2 className="text-xl font-bold p-4 border-b border-gray-700">Conversations</h2>
        {conversations.map((convo) => (
          <div
            key={convo.id}
            onClick={() => setSelectedConversation(convo)}
            className={`p-4 cursor-pointer hover:bg-gray-800 ${selectedConversation?.id === convo.id ? 'bg-gray-800' : ''}`}
          >
            <p className="font-semibold">{convo.users?.email || 'Unknown User'}</p>
            <p className="text-sm text-gray-400">{new Date(convo.created_at).toLocaleString()}</p>
            <span
              className={`text-xs font-bold uppercase px-2 py-1 rounded-full ${
                convo.status === 'open' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
              }`}
            >
              {convo.status}
            </span>
          </div>
        ))}
      </div>

      {/* Message Area */}
      <div className="w-2/3 flex flex-col">
        {selectedConversation ? (
          <>
            <div className="p-4 border-b border-gray-700">
              <h3 className="text-lg font-bold">Chat with {selectedConversation.users?.email || 'Unknown User'}</h3>
            </div>
            <div className="flex-1 p-4 overflow-y-auto">
              {messages.map((msg) => (
                <motion.div
                  key={msg.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={`mb-4 flex flex-col items-start ${
                    msg.sender_id === 'moderator' ? 'items-end' : ''
                  }`}>
                    <div className={`p-3 rounded-lg max-w-lg ${
                      msg.sender_id === 'moderator' ? 'bg-gold text-black ml-auto' : 'bg-gray-700 text-white'
                    }`}>
                      {msg.content && <p>{msg.content}</p>}
                      {renderMedia(msg)}
                      <span className="text-xs opacity-70 block text-right mt-1">
                        {new Date(msg.created_at).toLocaleTimeString()}
                      </span>
                    </div>
                </motion.div>
              ))}
            </div>
            <form onSubmit={handleSendMessage} className="p-4 border-t border-gray-700">
              <div className="flex items-center bg-gray-800 rounded-lg px-3">
                <input
                  type="text"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="Type a message..."
                  className="flex-1 bg-transparent text-white focus:outline-none py-3"
                />
                 <input type="file" ref={fileInputRef} onChange={handleFileChange} className="hidden" id="file-upload" />
                <label htmlFor="file-upload" className="cursor-pointer p-2 rounded-full hover:bg-gray-700">
                  <Paperclip className="text-gray-400" />
                </label>
                <button type="submit" className="p-2 rounded-full bg-gold text-black ml-2">
                  <Send />
                </button>
              </div>
                {mediaFile && (
                  <div className="mt-2 flex items-center bg-gray-800 p-2 rounded-lg">
                    <span className="text-sm text-gray-300 truncate">{mediaFile.name}</span>
                    <button onClick={() => setMediaFile(null)} className="ml-2 text-gray-400 hover:text-white">
                      <X size={16} />
                    </button>
                  </div>
                )}
            </form>
          </>
        ) : (
          <div className="flex items-center justify-center h-full">
            <p className="text-gray-400">Select a conversation to start chatting.</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default AdminChat;
