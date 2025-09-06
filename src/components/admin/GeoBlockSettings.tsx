import React, { useEffect, useState } from 'react';
import CountryBlockSelector from './CountryBlockSelector';

// À adapter selon ton setup
// const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
// const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
import { supabase } from '../../lib/supabase';

const TABLE = 'geo_block_settings';

const GeoBlockSettings: React.FC = () => {
    const [blockedCountries, setBlockedCountries] = useState<string[]>([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);

    // Charger la config au montage
    useEffect(() => {
        const fetchSettings = async () => {
            setLoading(true);
            setError(null);
            const { data, error } = await supabase
                .from(TABLE)
                .select('id, blocked_countries')
                .limit(1)
                .single();
            if (error) {
                setError("Erreur lors du chargement : " + error.message);
            } else if (data) {
                setBlockedCountries(data.blocked_countries || []);
            }
            setLoading(false);
        };
        fetchSettings();
    }, []);

    // Sauvegarder la config
    const handleSave = async () => {
        setSaving(true);
        setError(null);
        setSuccess(false);
        // On suppose une seule ligne (id connu)
        const { data, error } = await supabase
            .from(TABLE)
            .select('id')
            .limit(1)
            .single();
        if (error || !data) {
            setError("Impossible de trouver la config : " + (error?.message || '')); setSaving(false); return;
        }
        const { error: updateError } = await supabase
            .from(TABLE)
            .update({ blocked_countries: blockedCountries, updated_at: new Date().toISOString() })
            .eq('id', data.id);
        if (updateError) {
            setError("Erreur lors de la sauvegarde : " + updateError.message);
        } else {
            setSuccess(true);
        }
        setSaving(false);
    };

    return (
        <div>
            <h2 className="text-xl font-bold mb-4">Géoblocage par pays</h2>
            {loading ? (
                <div>Chargement...</div>
            ) : (
                <>
                    <CountryBlockSelector
                        value={blockedCountries}
                        onChange={setBlockedCountries}
                    />
                    <button
                        className="mt-4 px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
                        onClick={handleSave}
                        disabled={saving}
                    >
                        {saving ? 'Sauvegarde...' : 'Sauvegarder'}
                    </button>
                    {error && <div className="text-red-600 mt-2">{error}</div>}
                    {success && <div className="text-green-600 mt-2">Modifications enregistrées !</div>}
                </>
            )}
        </div>
    );
};

export default GeoBlockSettings; 