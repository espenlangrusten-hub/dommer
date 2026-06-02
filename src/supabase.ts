import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ocmdsghjehrckwtbehne.supabase.co';
const supabaseKey = 'sb_publishable_cyyC61FsotPK6jYsywC3JA_zpiDSWD-';

export const supabase = createClient(supabaseUrl, supabaseKey);
