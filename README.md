# Codely Bridge - Roblox Studio Plugin

Connect Roblox Studio to Codely CLI for AI-powered code assistance.

## 🎯 What This Plugin Does

This Roblox Studio plugin allows you to ask Codely CLI to execute commands directly in Roblox Studio:

- ✅ Create/modify scripts (Lua/Luau)
- ✅ Create game objects (Parts, Models, etc.)
- ✅ Add VFX (ParticleEmitters, Lights)
- ✅ Explore and inspect the game hierarchy
- ✅ Execute custom Luau code
- ✅ And much more!

## 📦 Installation

### Step 1: Download the Plugin

**Option A: From GitHub**
1. Go to: https://github.com/curzzed123/roblox-bridge
2. Download `CodelyBridge.lua` and `plugin.json`
3. Open Roblox Studio
4. Go to **File → Settings → Plugins** or use the Toolbox
5. Import the plugin files

**Option B: Copy Plugin Files**
1. Copy the `studio-plugin` folder
2. Paste it to your Roblox plugins directory:
   - Windows: `%LOCALAPPDATA%\Roblox\Plugins\`
   - Mac: `~/Library/Application Support/Roblox/Plugins/`
3. Restart Roblox Studio

### Step 2: Enable HTTP in Studio

**CRITICAL:** The plugin requires HTTP to be enabled.

**Method 1: Studio Settings (Recommended)**
1. Open Roblox Studio
2. Go to **File → Settings**
3. Navigate to **HTTP Requests**
4. Check **"Enable HTTP requests"**
5. Click **Save**
6. Restart Roblox Studio

**Method 2: Game Settings**
1. In Explorer, click on **Game**
2. In Properties, find **HttpEnabled**
3. Set it to **true**
4. Restart Roblox Studio

### Step 3: Enable the Plugin

1. Look for the **"Codely Bridge"** button in the toolbar
2. Click it to open the plugin panel
3. Should show: ✅ **Connected to Codely Bridge**

## 🚀 How to Use

### Using with Codely CLI

1. **Ask Codely** in your terminal/chat:
   ```
   "Create a health script in ServerScriptService"
   "Make a red Part at position 0, 5, 0"
   "Create ParticleEmitter for fire effects"
   "List all scripts in Workspace"
   ```

2. Codely will execute the command in Roblox Studio
3. Check the plugin panel for status and logs

### Available Commands

| Command | Description |
|---------|-------------|
| `create_script` | Create Script, LocalScript, or ModuleScript |
| `update_script` | Update existing script code |
| `create_object` | Create any Roblox instance (Part, Light, etc.) |
| `delete_object` | Delete any object |
| `get_object_info` | Get details about an object |
| `execute_luau` | Run raw Luau code |
| `list_objects` | List children of a path |

## 📝 Example Commands

### Script Creation
```
"Create a server script that prints 'Hello' every second"
"Create a module script with utility functions"
```

### Object Creation
```
"Create a red Part named Floor at position 0, -5, 0 with size 50, 1, 50"
"Create a SpawnLocation at 0, 10, 0"
"Create a PointLight with orange color"
```

### VFX
```
"Create a ParticleEmitter for fire effects"
"Add a Sound object with a gun shot sound"
"Create a Trail attachment to a part"
```

### Exploration
```
"List all objects in Workspace"
"Get info about the script at game.ServerScriptService.Main"
"Show me all scripts in the game"
```

## 🔍 Troubleshooting

### "HTTP not enabled" warning
- Follow the HTTP enable steps above
- Restart Roblox Studio

### "Connection lost" or red status
- Make sure the bridge server is running
- Check the server logs for errors
- Try clicking "Test Connection" in the plugin

### Plugin not showing in toolbar
1. Check files are in the plugins folder
2. Restart Roblox Studio
3. Check View → Plugins → Codely Bridge

### Commands not executing
1. Verify HTTP is enabled
2. Check plugin panel for error logs
3. Make sure Codely CLI is running

## ✅ Success Indicators

When everything is working:

- ✅ Plugin shows green status: "✅ Connected to Codely Bridge"
- ✅ Server is running
- ✅ You can send commands and receive responses
- ✅ Commands execute in Studio instantly

## 🛠️ Plugin Location

**Studio Installation:**
- Windows: `%LOCALAPPDATA%\Roblox\Plugins\CodelyBridge\`
- Mac: `~/Library/Application Support/Roblox/Plugins/CodelyBridge/`

**Plugin Files:**
- `CodelyBridge.lua` - Main plugin script
- `plugin.json` - Plugin manifest

## 📄 License

MIT License - Feel free to use and modify!

## 🤝 Support

For issues or questions:
- Check the troubleshooting section
- Enable HTTP in Studio if not working
- Verify server connection status

---

**Ready to code!** Just ask Codely what you want to create in Roblox Studio! 🎮