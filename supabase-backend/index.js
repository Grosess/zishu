const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'YOUR_ANON_KEY';
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Health check
app.get('/v1/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Sync endpoint
app.post('/v1/sync/learned', async (req, res) => {
  const { device_id, characters_count = 0, words_count = 0, total_practiced = 0 } = req.body;
  
  if (!device_id) {
    return res.status(400).json({ error: 'device_id required' });
  }
  
  try {
    // Upsert device data
    const { error } = await supabase
      .from('device_metrics')
      .upsert({
        device_id,
        characters: characters_count,
        words: words_count,
        practiced: total_practiced,
        last_seen: new Date().toISOString()
      });
    
    if (error) throw error;
    
    res.json({ 
      success: true, 
      sync_id: `sync_${Date.now()}`,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Metrics endpoint
app.get('/v1/metrics/global', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('global_metrics')
      .select('*')
      .single();
    
    if (error) throw error;
    
    res.json(data || {
      total_users: 0,
      total_characters_learned: 0,
      total_words_learned: 0,
      total_characters_practiced: 0,
      daily_active_users: 0,
      last_updated: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Track endpoint
app.post('/v1/track/learned', (req, res) => {
  res.json({ success: true, tracked: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;