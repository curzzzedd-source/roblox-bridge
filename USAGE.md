# Roblox Bridge - Complete Setup Guide

## 🎯 What This Does

You can now ask me (Codely CLI) in **this chat** to do things in **Roblox Studio**, and I'll execute them!

## 🚀 Quick Start

### 1. Server is running ✅
The bridge server is running at `http://localhost:7269`

### 2. Plugin is installed ✅
The plugin is in Roblox Studio at `%LOCALAPPDATA%\Roblox\Plugins\CodelyBridge\`

### 3. Restart Roblox Studio
Close and reopen Roblox Studio to load the updated plugin.

### 4. Start asking me! 💬
In this chat, just tell me what you want:

```
"Create a health script in ServerScriptService"
"Make a red part at position 0, 10, 0"
"List all scripts in Workspace"
"Delete the part called TestPart"
```

I'll execute it in Roblox Studio and tell you the result!

## 🎮 What I Can Do in Roblox Studio

### Coding
```
"Create a damage script for a sword"
"Update the script at game.ServerScriptService.Health to add regeneration"
```

### Objects
```
"Create a Part named Floor at position 0, -5, 0 with size 50, 1, 50"
"Create a SpawnLocation at 0, 10, 0"
```

### VFX
```
"Create a ParticleEmitter for fire effects"
"Add a PointLight to this part"
```

### Animations
```
"Create an Animation object in ReplicatedStorage"
"Create a humanoid animation script"
```

### Exploration
```
"List all objects in Workspace"
"Get info about the script at game.ServerScriptService.Main"
"Show me all scripts in the game"
```

## 🔧 Available Commands

| Command | What it does |
|---------|--------------|
| `create_script` | Create Script, LocalScript, or ModuleScript |
| `update_script` | Update existing script code |
| `create_object` | Create any Roblox instance (Part, Light, etc.) |
| `delete_object` | Delete any object |
| `get_object_info` | Get details about an object |
| `execute_luau` | Run raw Luau code |
| `list_objects` | List children of a path |

## 📝 Example Prompts

### Basic Scripts
```
"Create a server script that prints 'Hello World' every second"
```

### Game Systems
```
"Create a health system script with damage and heal functions"
```

### VFX
```
"Create a ParticleEmitter for an explosion effect"
"Add a PointLight with orange color and brightness 2"
```

### Objects
```
"Create a red Part at 0, 5, 0"
"Create a Script in StarterPlayerScripts that disables mouse lock"
```

## ⚠️ Important Notes

1. **Make sure Roblox Studio is open** - The plugin only works when Studio is running
2. **Commands execute in the active Studio session** - Make sure you have the right place open
3. **Check the plugin panel** - You can see command status in the Codely Bridge panel in Studio

## 🔍 Troubleshooting

**"Connection failed"**
- Make sure the bridge server is running
- Check that Roblox Studio is open
- Look for the "Codely Bridge" button in Studio toolbar

**Plugin not loading**
- Restart Roblox Studio
- Check the file is at `%LOCALAPPDATA%\Roblox\Plugins\CodelyBridge\CodelyBridge.lua`

**Commands not executing**
- Check the plugin panel in Studio for errors
- Make sure HTTP is enabled in Studio (View → HTTP Request Settings)

## 🎉 Ready to Use!

Just ask me what you want to create in Roblox Studio, and I'll do it!

Examples:
- "Create a game with a health system"
- "Add VFX to this sword"
- "Make a simple animation system"
- "Set up player spawn points"