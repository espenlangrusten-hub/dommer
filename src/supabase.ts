import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://ocmdsghjehrckwtbehne.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9jbWRzZ2hqZWhyY2t3dGJlaG5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzNzc2MTksImV4cCI6MjA5NTk1MzYxOX0.qmc2Zf4_SX1DpqI9-DXLMCnbae7Gc1TXpSXGeXnwUUM';

export const supabase = createClient(supabaseUrl, supabaseKey);
