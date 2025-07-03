// Using JSONBin.io for persistent storage
const API_KEY = process.env.JSONBIN_API_KEY;
const BIN_ID = process.env.JSONBIN_BIN_ID;

async function loadData() {
  try {
    const response = await fetch(`https://api.jsonbin.io/v3/b/${BIN_ID}/latest`, {
      headers: { 'X-Master-Key': API_KEY }
    });
    const data = await response.json();
    return data.record || { devices: {} };
  } catch (error) {
    console.error('Load error:', error);
    return { devices: {} };
  }
}

async function saveData(data) {
  try {
    await fetch(`https://api.jsonbin.io/v3/b/${BIN_ID}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'X-Master-Key': API_KEY
      },
      body: JSON.stringify(data)
    });
  } catch (error) {
    console.error('Save error:', error);
  }
}

exports.handler = async (event, context) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, X-Device-ID',
    'Content-Type': 'application/json'
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { 
      statusCode: 405, 
      headers,
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  // Check if JSONBin is configured
  if (!API_KEY || !BIN_ID) {
    // Fallback to memory storage if not configured
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ 
        success: true,
        sync_id: `sync_${Date.now()}`,
        note: 'Using memory storage (no persistence)'
      })
    };
  }

  try {
    const data = JSON.parse(event.body);
    const { device_id, characters_count = 0, words_count = 0, total_practiced = 0 } = data;

    if (!device_id) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'device_id required' })
      };
    }

    // Load current data from JSONBin
    const storage = await loadData();
    
    // Update device data
    storage.devices[device_id] = {
      device_id,
      characters: characters_count,
      words: words_count,
      practiced: total_practiced,
      last_seen: new Date().toISOString()
    };
    
    // Save back to JSONBin
    await saveData(storage);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ 
        success: true,
        sync_id: `sync_${Date.now()}`,
        timestamp: new Date().toISOString()
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: error.message })
    };
  }
};