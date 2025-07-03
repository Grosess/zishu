import { kv } from '@vercel/kv';

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-Device-ID');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  
  const { 
    device_id, 
    characters_count = 0, 
    words_count = 0, 
    total_practiced = 0 
  } = req.body;
  
  if (!device_id) {
    return res.status(400).json({ error: 'device_id required' });
  }
  
  try {
    // Store device data in Vercel KV (persistent storage!)
    await kv.hset('zishu:devices', device_id, JSON.stringify({
      device_id,
      characters: characters_count,
      words: words_count,
      practiced: total_practiced,
      last_seen: new Date().toISOString()
    }));
    
    res.status(200).json({ 
      success: true,
      sync_id: `sync_${Date.now()}`,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('KV Error:', error);
    res.status(500).json({ error: 'Storage error' });
  }
}