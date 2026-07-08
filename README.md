# Codely Bridge - Roblox Studio Plugin

Connect Roblox Studio to Codely CLI for AI-powered code assistance.

## Setup

### 1. Install the Bridge Server

Navigate to the server directory and install dependencies:

```bash
cd roblox-bridge/server
npm install
npm run build
```

### 2. Start the Server

```bash
npm start
```

You should see:
```
🚀 Roblox-Codely Bridge server running on http://localhost:7269
📋 Waiting for requests from Roblox Studio plugin...
```

### 3. Install the Plugin in Roblox Studio

1. Copy the `studio-plugin` folder to your Roblox plugins directory:
   - Windows: `%LOCALAPPDATA%\Roblox\Plugins\`
   - Mac: `~/Library/Application Support/Roblox/Plugins/`

   Or simply drag the `CodelyBridge.lua` file into Roblox Studio's Toolbox → Plugins folder.

2. Restart Roblox Studio.

### 4. Use the Plugin

1. Look for the "Codely Bridge" button in the toolbar.
2. Click it to open the panel.
3. Enter your query in the text box.
4. Click "Send to Codely".
5. The response will appear below.

## How It Works

```
Roblox Studio Plugin
        ↓ (HTTP Request)
   Bridge Server (Node.js)
        ↓ (Queue)
   Codely CLI (me!) ← You interact with me here
        ↓ (Response)
   Bridge Server
        ↓ (HTTP Response)
Roblox Studio Plugin
```

## Features

- ✅ Send code requests directly from Studio
- ✅ Get AI-powered responses
- ✅ Automatic script context detection
- ✅ Real-time connection status

## Troubleshooting

**"Server not connected"**
- Make sure the Node.js server is running (`npm start`)
- Check that port 7269 is not blocked

**Requests timing out**
- Make sure Codely CLI is active and responsive
- Check the server terminal for any errors

**Plugin not showing up**
- Make sure the plugin file is in the correct plugins folder
- Restart Roblox Studio after copying the plugin