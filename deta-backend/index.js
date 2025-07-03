const express = require('express');
const cors = require('cors');
const { Deta } = require('deta');

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Deta (FREE database!)
const deta = Deta(process.env.DETA_PROJECT_KEY);
const db = deta.Base('zishu_metrics');

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
    // Save to Deta database
    await db.put({
      key: device_id,
      device_id,
      characters: characters_count,
      words: words_count,
      practiced: total_practiced,
      last_seen: new Date().toISOString()
    });
    
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
    // Fetch all devices from Deta
    const result = await db.fetch();
    const devices = result.items;
    
    // Calculate metrics
    const metrics = {
      total_users: devices.length,
      total_characters_learned: devices.reduce((sum, d) => sum + (d.characters || 0), 0),
      total_words_learned: devices.reduce((sum, d) => sum + (d.words || 0), 0),
      total_characters_practiced: devices.reduce((sum, d) => sum + (d.practiced || 0), 0),
      daily_active_users: devices.length,
      last_updated: new Date().toISOString()
    };
    
    res.json(metrics);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Track endpoint
app.post('/v1/track/learned', (req, res) => {
  res.json({ success: true, tracked: true });
});

module.exports = app;