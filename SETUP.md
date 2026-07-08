# Codely Bridge - Complete Setup Guide

## 🎯 What This Does

This creates a direct connection between Roblox Studio and me (Codely CLI) so you can:

1. Ask for code help from inside Roblox Studio
2. Get AI responses from Codely CLI
3. Use context from your selected scripts

## 📁 File Structure

```
roblox-bridge/
├── server/                    # Node.js HTTP server
│   ├── src/
│   │   └── index.ts          # Server code
│   ├── dist/                 # Compiled JS
│   ├── package.json
│   └── tsconfig.json
├── studio-plugin/
│   ├── CodelyBridge.lua      # Roblox Studio plugin
│   └── plugin.json
├── test-request.js           # Test script
└── README.md
```

## 🚀 Quick Setup

### Step 1: The server is already running ✅

The bridge server is currently running at `http://localhost:7269`

### Step 2: Install the Roblox Studio Plugin

**Option A: Copy to plugins folder**
```powershell
# Copy the plugin to Roblox plugins directory
Copy-Item -Recurse "C:\Users\ziyad\.codely\Default\roblox-bridge\studio-plugin\*" "$env:LOCALAPPDATA\Roblox\Plugins\CodelyBridge\"
```

**Option B: Manual installation**
1. Open Roblox Studio
2. Open Toolbox
3. Go to "My Plugins" or create a new plugin
4. Copy the contents of `CodelyBridge.lua` into the plugin script
5. Save

### Step 3: Restart Roblox Studio

After installing, close and reopen Roblox Studio.

### Step 4: Use the Plugin

1. Look for "Codely Bridge" button in the toolbar (usually top)
2. Click it to open the panel
3. Enter your query (e.g., "Create a health system script")
4. Click "Send to Codely"
5. Wait for response!

## 🔄 How I (Codely) Will Process Requests

When you send a request from Roblox Studio:

1. **Request arrives at the server**
2. **I'll check the queue periodically** and see your request
3. **I'll process it** using my capabilities
4. **I'll send the response back** to the server
5. **Roblox Studio displays the result**

## 🛠️ Testing the Bridge

To verify everything works, run:

```powershell
cd C:\Users\ziyad\.codely\Default\roblox-bridge\server
npm test
```

You should see a successful test response.

## 📋 Common Queries to Try

Once connected, try these in the plugin:

- "Create a server script that damages players when they touch a part"
- "Help me fix this script: [paste error]"
- "Create a data store system for saving player data"
- "Optimize this script for better performance"

## ⚠️ Troubleshooting

**Status says "Server not connected"**
- Make sure the Node.js server is running (check terminal)
- The server is currently running at `localhost:7269`

**Plugin not showing in toolbar**
- Check the file was copied to `%LOCALAPPDATA%\Roblox\Plugins\`
- Restart Roblox Studio
- Check plugin is enabled in View → Plugins

**No response to requests**
- Check the server terminal for errors
- Make sure I (Codely CLI) am active
- Try restarting the server (Ctrl+C, then `npm start`)

**Port already in use**
- Kill existing process on port 7269:
  ```powershell
  Get-NetTCPConnection -LocalPort 7269 | ForEach-Object { Stop-Process -Id $_.OwningProcess }
  ```
- Or change the port in `server/src/index.ts` (line 5)

## 🎉 Success Indicators

When everything is working:

- ✅ Server terminal shows: `🚀 Roblox-Codely Bridge server running`
- ✅ Plugin shows green status: "✅ Connected to Codely Bridge"
- ✅ You can send queries and receive responses
- ✅ Responses appear in the plugin panel

## 📝 Next Steps

Once connected, you can ask me to:

1. Generate Roblox Luau scripts
2. Debug existing code
3. Explain Roblox APIs
4. Create systems (health, inventory, etc.)
5. Optimize performance

Just ask from the plugin and I'll help you!