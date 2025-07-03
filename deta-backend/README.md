# Deploy to Deta Space (FREE with Real Database!)

## Quick Setup (5 minutes)

1. **Sign up at Deta Space** (100% FREE)
   - Go to https://deta.space
   - Click "Start Building"
   - Sign up with email

2. **Install Deta Space CLI**
   ```bash
   curl -fsSL https://get.deta.dev/space-cli.sh | sh
   ```

3. **Login**
   ```bash
   space login
   ```

4. **Create Spacefile**
   Create `Spacefile` in this directory:
   ```yaml
   v: 0
   micros:
     - name: zishu-backend
       src: .
       engine: nodejs16
       public: true
       run: node index.js
   ```

5. **Deploy**
   ```bash
   space push
   space release
   ```

6. **Get your URL**
   After deployment, you'll get a URL like:
   `https://zishu-backend-1-a1234567.deta.app`

7. **Update Flutter app**
   Change the URL in `sync_service.dart` to your Deta URL

## That's it!

Your metrics will now persist forever in a real database, completely FREE!