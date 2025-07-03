const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// Data file
const dataFile = path.join(__dirname, 'data.json');

// Load or create data
function loadData() {
  try {
    return JSON.parse(fs.readFileSync(dataFile, 'utf8'));
  } catch (error) {
    const initialData = { devices: {} };
    fs.writeFileSync(dataFile, JSON.stringify(initialData, null, 2));
    return initialData;
  }
}

// Save data
function saveData(data) {
  fs.writeFileSync(dataFile, JSON.stringify(data, null, 2));
}

// Routes
app.get('/v1/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/v1/sync/learned', (req, res) => {
  const { device_id, characters_count = 0, words_count = 0, total_practiced = 0 } = req.body;
  
  if (!device_id) {
    return res.status(400).json({ error: 'device_id required' });
  }
  
  const data = loadData();
  data.devices[device_id] = {
    device_id,
    characters: characters_count,
    words: words_count,
    practiced: total_practiced,
    last_seen: new Date().toISOString()
  };
  saveData(data);
  
  res.json({ success: true, sync_id: `sync_${Date.now()}` });
});

app.get('/v1/metrics/global', (req, res) => {
  const data = loadData();
  const devices = Object.values(data.devices);
  
  res.json({
    total_users: devices.length,
    total_characters_learned: devices.reduce((sum, d) => sum + (d.characters || 0), 0),
    total_words_learned: devices.reduce((sum, d) => sum + (d.words || 0), 0),
    total_characters_practiced: devices.reduce((sum, d) => sum + (d.practiced || 0), 0),
    daily_active_users: devices.length,
    last_updated: new Date().toISOString()
  });
});

app.post('/v1/track/learned', (req, res) => {
  res.json({ success: true, tracked: true });
});

const PORT = 3456;
app.listen(PORT, () => {
  console.log(`✨ Zishu backend running at http://localhost:${PORT}`);
  console.log(`📊 Metrics visible at http://localhost:${PORT}/v1/metrics/global`);
});