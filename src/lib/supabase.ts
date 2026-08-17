import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export const isSupabaseConfigured = () => {
  return supabaseUrl !== '' && supabaseUrl !== 'https://tu-proyecto.supabase.co' &&
         supabaseAnonKey !== '' && supabaseAnonKey !== 'tu-anon-key';
};
