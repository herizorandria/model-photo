import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Auth } from '@supabase/auth-ui-react';
import { ThemeSupa } from '@supabase/auth-ui-shared';

const AuthForm: React.FC = () => {
  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-gray-800/50 backdrop-blur-md p-8 rounded-2xl shadow-lg border border-gray-700">
        <Auth
          supabaseClient={supabase}
          appearance={{ 
            theme: ThemeSupa,
            style: {
              button: { background: '#D4AF37', color: 'black', borderRadius: '9999px', borderColor: '#D4AF37' },
              anchor: { color: '#D4AF37' },
              input: { background: '#1F2937', color: 'white', borderWidth: '1px', borderColor: '#4B5563', borderRadius: '8px' },
              label: { color: 'white'},
              message: { color: '#EF4444' }
            },
          }}
          theme="dark"
          providers={[]}
          localization={{
            variables: {
              sign_in: {
                email_label: 'Adresse e-mail',
                password_label: 'Mot de passe',
                button_label: 'Se connecter',
                social_provider_text: 'Se connecter avec',
                link_text: 'Déjà un compte ? Connectez-vous'
              },
              sign_up: {
                email_label: 'Adresse e-mail',
                password_label: 'Mot de passe',
                button_label: 'S\'inscrire',
                social_provider_text: 'S\'inscrire avec',
                link_text: 'Pas de compte ? Inscrivez-vous'
              },
              forgotten_password: {
                email_label: 'Adresse e-mail',
                password_label: 'Mot de passe',
                button_label: 'Réinitialiser le mot de passe',
                link_text: 'Mot de passe oublié ?'
              }
            }
          }}
        />
      </div>
    </div>
  );
};

export default AuthForm;
