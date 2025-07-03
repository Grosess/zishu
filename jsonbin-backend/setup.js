// JSONBin.io backend setup
// This gives us a FREE database that actually persists data!

const API_KEY = '$2a$10$YOUR_API_KEY_HERE'; // You'll get this from jsonbin.io
const BIN_ID = 'YOUR_BIN_ID_HERE'; // You'll get this after creating a bin

// This is what our Netlify functions will use to save/load data
const JSONBIN_API = {
  read: async () => {
    const response = await fetch(`https://api.jsonbin.io/v3/b/${BIN_ID}/latest`, {
      headers: { 'X-Master-Key': API_KEY }
    });
    const data = await response.json();
    return data.record;
  },
  
  update: async (data) => {
    const response = await fetch(`https://api.jsonbin.io/v3/b/${BIN_ID}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'X-Master-Key': API_KEY
      },
      body: JSON.stringify(data)
    });
    return response.json();
  }
};

console.log(`
QUICK SETUP:
1. Go to https://jsonbin.io
2. Sign up (FREE - just need email)
3. Get your API key from dashboard
4. Create a new bin with this JSON: {"devices":{}}
5. Copy the bin ID from the URL
6. I'll update your backend!
`);