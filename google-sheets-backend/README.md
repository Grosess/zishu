# FREE Backend using Google Sheets!

This is the simplest solution that actually works for publishing.

## Setup (5 minutes)

1. **Create a Google Sheet**
   - Go to https://sheets.google.com
   - Create a new spreadsheet
   - Name it "Zishu Metrics"
   - In row 1, add headers: `device_id`, `characters`, `words`, `practiced`, `last_seen`

2. **Make it publicly editable**
   - Click Share button
   - Change to "Anyone with the link can edit"
   - Copy the sheet ID from the URL (the long string between /d/ and /edit)

3. **Deploy this simple API to Netlify**
   - The API uses Google Sheets as database
   - Data persists forever
   - 100% free

4. **Update your Flutter app**
   - Just change the backend URL

That's it! Your metrics will work and persist data.