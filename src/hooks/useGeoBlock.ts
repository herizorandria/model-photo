import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export default function useGeoBlock() {
  const [isBlocked, setIsBlocked] = useState<boolean | null>(null);
  const [loadingBlock, setLoadingBlock] = useState(true);

  useEffect(() => {
    let isMounted = true;
    const checkGeoBlock = async () => {
      const { data, error } = await supabase
        .from('geo_block_settings')
        .select('blocked_countries')
        .limit(1)
        .single();
      if (error || !data || !Array.isArray(data.blocked_countries)) {
        setIsBlocked(false);
        setLoadingBlock(false);
        return;
      }
      const blockedCountries = data.blocked_countries;
      try {
        const geo = await fetch('/api/geoip').then(res => res.json());
        if (!isMounted) return;
        if (blockedCountries.includes(geo.country_code)) {
          await supabase.from('geo_block_logs').insert({
            country_code: geo.country_code,
            ip: geo.ip,
            blocked_at: new Date().toISOString(),
          });
          setIsBlocked(true);
        } else {
          setIsBlocked(false);
        }
      } catch {
        setIsBlocked(false);
      } finally {
        setLoadingBlock(false);
      }
    };
    checkGeoBlock();
    return () => { isMounted = false; };
  }, []);

  return { isBlocked, loadingBlock };
}
