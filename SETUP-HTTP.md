# Codely Bridge - Setup & Troubleshooting

## ✅ Plugin Installed
Location: `%LOCALAPPDATA%\Roblox\Plugins\CodelyBridge\CodelyBridge.lua`

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

## 🚀 How to Use

1. **Start the bridge server** (if not running):
   ```powershell
   cd C:\Users\ziyad\.codely\Default\roblox-bridge\server
   npm start
   ```

2. **Open Roblox Studio** with HTTP enabled

3. **Look for the "Codely Bridge" button** in the toolbar

4. **Click it** to open the panel

5. **Ask Codely** in this terminal to do things in Studio!

## 🎮 Example Commands

In this chat, ask me to:

```
"Create a health script in ServerScriptService"
"Make a red Part at position 0, 5, 0"
"List all scripts in Workspace"
"Create a ParticleEmitter for fire effects"
```

## 🔍 Troubleshooting

### "HTTP not enabled" warning
- Follow the steps above to enable HTTP
- Restart Roblox Studio

### "Connection lost" or red status
- Make sure the bridge server is running
- Check terminal for errors
- Try clicking "Test Connection" in the plugin

### "Timeout waiting for result"
- Make sure Roblox Studio is open
- Make sure the plugin is loaded (green status)
- Check the plugin panel for error logs

### Plugin not showing up
1. Check the file is in `%LOCALAPPDATA%\Roblox\Plugins\CodelyBridge\`
2. Restart Roblox Studio
3. Check View → Plugins → Codely Bridge

## ✅ Success Indicators

When everything works:

- ✅ Plugin shows green status: "✅ Connected to Codely Bridge"
- ✅ Bridge server is running (see terminal)
- ✅ You can send commands and receive responses
- ✅ Commands execute in Studio instantly

## 📝 Quick Test

Once set up, ask me:
```
"Test the Roblox Bridge connection"
```

I'll send a test command and verify everything works!

## 🎉 Ready to Go!

Once HTTP is enabled and you restart Studio, just ask me what you want to create in Roblox Studio, and I'll do it!