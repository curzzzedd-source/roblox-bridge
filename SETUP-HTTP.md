# Codely Bridge - Plugin Setup

## ✅ Plugin Installed

Location: `studio-plugin/CodelyBridge.lua`

## ⚠️ CRITICAL: Enable HTTP in Roblox Studio

The plugin **won't work** until HTTP is enabled in Studio.

### Method 1: Via Studio Settings (Recommended)

1. Open Roblox Studio
2. Go to **File** → **Settings** (or Ctrl + ,)
3. Navigate to **HTTP Requests**
4. Check **"Enable HTTP requests"**
5. Click **Save**
6. Restart Roblox Studio

### Method 2: Via Game Settings

1. Open any place in Roblox Studio
2. In **Explorer**, click on **Game** (at the top)
3. In **Properties**, find **HttpEnabled**
4. Set it to **true**
5. Restart Roblox Studio

### Method 3: Via Script

Run this in the command bar (View → Command Bar):

```lua
game:GetService("HttpService").HttpEnabled = true
```

## 📦 Install the Plugin

### Option A: Install from GitHub Releases
1. Download the latest release from GitHub
2. Extract the plugin files
3. Open Roblox Studio
4. Go to **File → Settings → Plugins**
5. Click **"Add Plugin"** and select the files

### Option B: Copy Plugin Files Manually
1. Copy the `studio-plugin` folder
2. Paste it to:
   - **Windows**: `%LOCALAPPDATA%\Roblox\Plugins\`
   - **Mac**: `~/Library/Application Support/Roblox/Plugins/`
3. Restart Roblox Studio

### Option C: Import via Toolbox
1. Open Roblox Studio
2. Open the **Toolbox**
3. Go to **My Plugins**
4. Drag and drop `CodelyBridge.lua` into the folder
5. Save and restart Studio

## 🚀 Server Connection

The plugin connects to a bridge server that handles communication with Codely CLI.

### Default Configuration
- **Server URL**: `http://localhost:7269`
- **Protocol**: HTTP (not HTTPS)
- **Port**: 7269

### Connecting to a Different Server
To connect to a remote/hosed server, edit `CodelyBridge.lua` and change:

```lua
-- Line 10: Change the SERVER_URL
local SERVER_URL = "http://your-server-url:port"
```

Example:
```lua
local SERVER_URL = "http://my-bridge-server.com:7269"
```

## 🔍 Troubleshooting

### "HTTP not enabled" warning
- Follow the steps above to enable HTTP
- Restart Roblox Studio

### "Cannot connect to server"
1. Check if the bridge server is running
2. Verify the server URL in the plugin
3. Check network/firewall settings
4. Try pinging the server address

### "Connection lost" or red status
- Make sure the bridge server is running
- Check server logs for errors
- Verify server URL is correct
- Try clicking "Test Connection" button

### Plugin not showing up
1. Check files are in the plugins folder
2. Restart Roblox Studio
3. Check View → Plugins → Codely Bridge
4. Make sure `plugin.json` exists

### Commands timing out
- Verify server is running and responsive
- Check server logs for errors
- Check network connection
- Verify HTTP is enabled in Studio

## ✅ Verify Installation

After installing:

1. **Open Roblox Studio**
2. **Look for "Codely Bridge" button** in toolbar
3. **Click it** to open the panel
4. **Check status**: Should show ✅ green
5. **Click "Test Connection"** to verify

## 📝 Plugin Files

```
CodelyBridge/
├── CodelyBridge.lua    # Main plugin script
└── plugin.json          # Plugin manifest
```

## 🎉 Ready to Use!

Once HTTP is enabled and the plugin is loaded, ask Codely to execute commands in Studio!

---

**Need help?** Check the main README.md for usage examples!