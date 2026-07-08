#!/usr/bin/env python3
"""
Roblox FFlags Manager
=====================
Dump, set, and watch Roblox Fast Flags via ClientAppSettings.json.

Usage:
    python fflags.py dump                  Dump all FFlags to a file
    python fflags.py list                  List all current FFlags
    python fflags.py set <key> <value>     Set an FFlag
    python fflags.py del <key>             Delete an FFlag
    python fflags.py watch                 Live watch mode (auto-reload)
    python fflags.py import <file>         Import FFlags from JSON file
    python fflags.py export <file>         Export FFlags to JSON file
    python fflags.py backup                Create a backup
    python fflags.py restore <file>       Restore from a backup
    python fflags.py presets               List available presets
    python fflags.py apply <preset>        Apply a preset
    python fflags.py clear                 Remove all custom FFlags
    python fflags.py info                  Show Roblox version info

Options:
    --target <player|studio|all>   Target Roblox Player, Studio, or both (default: player)
    --no-backup                    Skip automatic backup before writing
"""

import os
import sys
import json
import time
import shutil
import glob
import subprocess
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

LOCAL_APPDATA = os.environ.get("LOCALAPPDATA", os.path.expanduser("~\\AppData\\Local"))
ROBLOX_VERSIONS_DIR = os.path.join(LOCAL_APPDATA, "Roblox", "Versions")
CLIENT_SETTINGS_FILE = "ClientAppSettings.json"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKUP_DIR = os.path.join(SCRIPT_DIR, "fflags-backups")
DUMP_DIR = os.path.join(SCRIPT_DIR, "fflags-dumps")
PRESETS_DIR = os.path.join(SCRIPT_DIR, "fflags-presets")

# ---------------------------------------------------------------------------
# Colors (Windows ANSI)
# ---------------------------------------------------------------------------

class C:
    RESET   = "\033[0m"
    BOLD    = "\033[1m"
    RED     = "\033[91m"
    GREEN   = "\033[92m"
    YELLOW  = "\033[93m"
    BLUE    = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN    = "\033[96m"
    DIM     = "\033[2m"

# Force UTF-8 stdout/stderr (Windows defaults to cp1252)
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    os.system("")  # Enable ANSI colors

# ---------------------------------------------------------------------------
# FFlag type detection
# ---------------------------------------------------------------------------

FLAG_TYPES = {
    "FFlag":  {"label": "Bool",   "color": C.GREEN},
    "DFInt":  {"label": "Int",    "color": C.CYAN},
    "FInt":   {"label": "Int",    "color": C.CYAN},
    "FString":{"label": "String", "color": C.YELLOW},
    "FBool":  {"label": "Bool",   "color": C.GREEN},
    "DFInt":  {"label": "Int",    "color": C.CYAN},
    "FFloat": {"label": "Float",  "color": C.MAGENTA},
    "DFFloat":{"label": "Float",  "color": C.MAGENTA},
}

def flag_type(key):
    for prefix, info in FLAG_TYPES.items():
        if key.startswith(prefix):
            return info
    return {"label": "??", "color": C.DIM}

# ---------------------------------------------------------------------------
# Roblox process detection
# ---------------------------------------------------------------------------

def is_roblox_running():
    """Check if RobloxPlayerBeta.exe or RobloxStudioBeta.exe is running."""
    try:
        result = subprocess.run(
            ["tasklist", "/FI", "IMAGENAME eq RobloxPlayerBeta.exe", "/NH"],
            capture_output=True, text=True, timeout=5
        )
        if "RobloxPlayerBeta.exe" in result.stdout:
            return "player"
    except Exception:
        pass
    try:
        result = subprocess.run(
            ["tasklist", "/FI", "IMAGENAME eq RobloxStudioBeta.exe", "/NH"],
            capture_output=True, text=True, timeout=5
        )
        if "RobloxStudioBeta.exe" in result.stdout:
            return "studio"
    except Exception:
        pass
    return None

# ---------------------------------------------------------------------------
# Version folder discovery
# ---------------------------------------------------------------------------

def find_version_dirs(target="player"):
    """Find Roblox version directories."""
    if not os.path.exists(ROBLOX_VERSIONS_DIR):
        return []

    version_folders = sorted(glob.glob(os.path.join(ROBLOX_VERSIONS_DIR, "version-*")))
    results = []

    for folder in version_folders:
        has_player = os.path.exists(os.path.join(folder, "RobloxPlayerBeta.exe"))
        has_studio = os.path.exists(os.path.join(folder, "RobloxStudioBeta.exe"))

        if target == "player" and has_player:
            results.append({"path": folder, "type": "player"})
        elif target == "studio" and has_studio:
            results.append({"path": folder, "type": "studio"})
        elif target == "all" and (has_player or has_studio):
            t = "player" if has_player else "studio"
            results.append({"path": folder, "type": t})

    # Fallback: if nothing matched, grab any version folder
    if not results and version_folders:
        for folder in version_folders:
            results.append({"path": folder, "type": "unknown"})

    return results

def get_settings_path(version_dir):
    """Get the ClientAppSettings.json path for a version directory."""
    return os.path.join(version_dir, CLIENT_SETTINGS_FILE)

def read_fflags(version_dir):
    """Read FFlags from ClientAppSettings.json. Returns empty dict if missing."""
    path = get_settings_path(version_dir)
    if not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            return {}
        return data
    except (json.JSONDecodeError, OSError) as e:
        print(f"{C.RED}Error reading {path}: {e}{C.RESET}")
        return {}

def write_fflags(version_dir, flags, create_backup=True):
    """Write FFlags to ClientAppSettings.json."""
    path = get_settings_path(version_dir)

    if create_backup and os.path.exists(path):
        backup_fflags(version_dir)

    # Ensure parent dir exists
    os.makedirs(version_dir, exist_ok=True)

    with open(path, "w", encoding="utf-8") as f:
        json.dump(flags, f, indent=4, sort_keys=True)
        f.write("\n")

# ---------------------------------------------------------------------------
# Backup / Restore
# ---------------------------------------------------------------------------

def backup_fflags(version_dir):
    """Create a timestamped backup of ClientAppSettings.json."""
    path = get_settings_path(version_dir)
    if not os.path.exists(path):
        return None

    os.makedirs(BACKUP_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    version_name = os.path.basename(version_dir)
    backup_name = f"{version_name}_{timestamp}.json"
    backup_path = os.path.join(BACKUP_DIR, backup_name)

    shutil.copy2(path, backup_path)
    return backup_path

def list_backups():
    """List all available backups."""
    if not os.path.exists(BACKUP_DIR):
        return []
    backups = sorted(glob.glob(os.path.join(BACKUP_DIR, "*.json")), reverse=True)
    return backups

def restore_fflags(version_dir, backup_path):
    """Restore ClientAppSettings.json from a backup file."""
    if not os.path.exists(backup_path):
        print(f"{C.RED}Backup file not found: {backup_path}{C.RESET}")
        return False

    path = get_settings_path(version_dir)

    # Backup current before restoring
    if os.path.exists(path):
        backup_fflags(version_dir)

    shutil.copy2(backup_path, path)
    return True

# ---------------------------------------------------------------------------
# Dump
# ---------------------------------------------------------------------------

def dump_fflags(version_dir, label=""):
    """Dump all FFlags to a file in fflags-dumps/."""
    flags = read_fflags(version_dir)
    if not flags:
        print(f"{C.YELLOW}No FFlags found in {os.path.basename(version_dir)}{C.RESET}")
        return None

    os.makedirs(DUMP_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    version_name = os.path.basename(version_dir)
    dump_name = f"dump_{version_name}_{timestamp}.json"
    dump_path = os.path.join(DUMP_DIR, dump_name)

    with open(dump_path, "w", encoding="utf-8") as f:
        json.dump(flags, f, indent=4, sort_keys=True)
        f.write("\n")

    return dump_path

# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

def print_fflags_table(flags, title="FFlags"):
    """Print FFlags in a formatted table."""
    if not flags:
        print(f"{C.DIM}  (no FFlags set){C.RESET}")
        return

    # Sort by key
    sorted_flags = sorted(flags.items())

    # Calculate column widths
    max_key = max(len(k) for k, _ in sorted_flags)
    max_key = min(max_key, 60)

    print(f"\n{C.BOLD}{C.BLUE}{'=' * (max_key + 30)}{C.RESET}")
    print(f"{C.BOLD}{C.BLUE} {title} — {len(flags)} flags{C.RESET}")
    print(f"{C.BOLD}{C.BLUE}{'=' * (max_key + 30)}{C.RESET}\n")

    print(f"  {C.BOLD}{'Key':<{max_key}}  {'Type':<8}  Value{C.RESET}")
    print(f"  {'-' * max_key}  {'-' * 8}  {'-' * 30}")

    for key, value in sorted_flags:
        ft = flag_type(key)
        val_str = str(value)
        # Truncate long values
        if len(val_str) > 50:
            val_str = val_str[:47] + "..."

        print(f"  {ft['color']}{key:<{max_key}}{C.RESET}  "
              f"{C.DIM}{ft['label']:<8}{C.RESET}  "
              f"{C.YELLOW}{val_str}{C.RESET}")

    print()

def print_info(version_dirs):
    """Print Roblox version info."""
    print(f"\n{C.BOLD}{C.BLUE}Roblox FFlags Manager — Info{C.RESET}\n")
    print(f"  {C.DIM}Versions directory:{C.RESET} {ROBLOX_VERSIONS_DIR}")
    print(f"  {C.DIM}Exists:{C.RESET} {'yes' if os.path.exists(ROBLOX_VERSIONS_DIR) else 'no'}\n")

    if not version_dirs:
        print(f"  {C.RED}No Roblox version folders found.{C.RESET}")
        return

    running = is_roblox_running()

    for vd in version_dirs:
        vtype = vd["type"]
        vpath = vd["path"]
        vname = os.path.basename(vpath)
        settings_path = get_settings_path(vpath)
        has_settings = os.path.exists(settings_path)
        flags = read_fflags(vpath) if has_settings else {}

        status_icon = f"{C.GREEN}●{C.RESET}" if has_settings else f"{C.DIM}○{C.RESET}"
        running_tag = f"  {C.YELLOW}[RUNNING]{C.RESET}" if running and running == vtype else ""

        print(f"  {status_icon} {C.BOLD}{vname}{C.RESET} ({vtype}){running_tag}")
        print(f"    {C.DIM}Path:{C.RESET} {vpath}")
        print(f"    {C.DIM}Settings:{C.RESET} {'exists' if has_settings else 'not created'}"
              f" ({len(flags)} flags)")
        print()

# ---------------------------------------------------------------------------
# Watch mode
# ---------------------------------------------------------------------------

def watch_mode(version_dirs):
    """Watch ClientAppSettings.json for changes and auto-reload."""
    print(f"\n{C.BOLD}{C.CYAN}╔══════════════════════════════════════════════╗{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}║       FFlags Watch Mode — Live Monitor       ║{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}╚══════════════════════════════════════════════╝{C.RESET}")
    print(f"  {C.DIM}Press Ctrl+C to stop.{C.RESET}\n")

    # Track file modification times
    file_mtimes = {}
    was_running = is_roblox_running()

    for vd in version_dirs:
        path = get_settings_path(vd["path"])
        if os.path.exists(path):
            file_mtimes[path] = os.path.getmtime(path)
        else:
            file_mtimes[path] = 0

    if was_running:
        print(f"  {C.YELLOW}⚠ Roblox ({was_running}) is running. Changes need restart to take effect.{C.RESET}\n")

    # Initial dump
    for vd in version_dirs:
        flags = read_fflags(vd["path"])
        print_fflags_table(flags, f"{os.path.basename(vd['path'])} ({vd['type']})")

    print(f"  {C.DIM}Watching for changes...{C.RESET}\n")

    try:
        while True:
            time.sleep(1)

            # Check for file changes
            for vd in version_dirs:
                path = get_settings_path(vd["path"])
                try:
                    current_mtime = os.path.getmtime(path) if os.path.exists(path) else 0
                except OSError:
                    continue

                if path not in file_mtimes:
                    file_mtimes[path] = current_mtime
                    continue

                if current_mtime != file_mtimes[path]:
                    file_mtimes[path] = current_mtime
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    print(f"\n{C.GREEN}[{timestamp}] File changed — reloading...{C.RESET}")
                    flags = read_fflags(vd["path"])
                    print_fflags_table(flags, f"{os.path.basename(vd['path'])} ({vd['type']})")
                    print(f"  {C.DIM}Watching for changes...{C.RESET}\n")

            # Check for Roblox process changes
            now_running = is_roblox_running()
            if now_running != was_running:
                was_running = now_running
                timestamp = datetime.now().strftime("%H:%M:%S")
                if now_running:
                    print(f"\n{C.YELLOW}[{timestamp}] Roblox ({now_running}) started — "
                          f"restart to apply new FFlags.{C.RESET}\n")
                else:
                    print(f"\n{C.CYAN}[{timestamp}] Roblox stopped — "
                          f"safe to modify FFlags now.{C.RESET}\n")

    except KeyboardInterrupt:
        print(f"\n\n{C.DIM}Watch stopped.{C.RESET}")

# ---------------------------------------------------------------------------
# Presets
# ---------------------------------------------------------------------------

# Built-in presets
BUILTIN_PRESETS = {
    "unlock-fps": {
        "description": "Unlock FPS (removes 60fps cap)",
        "flags": {
            "DFIntTaskSchedulerTargetFps": "9999"
        }
    },
    "disable-postfx": {
        "description": "Disable post-processing effects (bloom, blur, etc.)",
        "flags": {
            "FFlagDisablePostProcessing": "True"
        }
    },
    "no-voicechat": {
        "description": "Disable voice chat",
        "flags": {
            "FFlagDisableVoiceChat": "True"
        }
    },
    "fast-render": {
        "description": "Optimize rendering for performance",
        "flags": {
            "FFlagDebugGraphicsPreferD3D11": "True",
            "FIntDebugForceMSAASamples": "1",
            "FFlagDisablePostProcessing": "True",
            "DFIntTaskSchedulerTargetFps": "9999"
        }
    },
    "quality-max": {
        "description": "Max graphics quality",
        "flags": {
            "FIntDebugForceMSAASamples": "8",
            "DFIntTaskSchedulerTargetFps": "9999"
        }
    },
    "minimal": {
        "description": "Minimal flags — bare essentials",
        "flags": {
            "DFIntTaskSchedulerTargetFps": "9999"
        }
    },
}

def list_presets():
    """List all available presets."""
    print(f"\n{C.BOLD}{C.BLUE}Available FFlag Presets{C.RESET}\n")
    print(f"  {C.BOLD}{'Name':<20} Description{C.RESET}")
    print(f"  {'-' * 20} {'-' * 50}")

    for name, preset in sorted(BUILTIN_PRESETS.items()):
        flag_count = len(preset["flags"])
        print(f"  {C.CYAN}{name:<20}{C.RESET} {preset['description']}")
        print(f"  {'':<20} {C.DIM}{flag_count} flag(s){C.RESET}")

    # Check for custom presets
    if os.path.exists(PRESETS_DIR):
        custom = sorted(glob.glob(os.path.join(PRESETS_DIR, "*.json")))
        if custom:
            print(f"\n  {C.BOLD}Custom Presets:{C.RESET}\n")
            for path in custom:
                name = Path(path).stem
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                    desc = data.get("description", "")
                    flags = data.get("flags", {})
                    print(f"  {C.MAGENTA}{name:<20}{C.RESET} {desc}")
                    print(f"  {'':<20} {C.DIM}{len(flags)} flag(s){C.RESET}")
                except (json.JSONDecodeError, OSError):
                    print(f"  {C.RED}{name:<20} (invalid JSON){C.RESET}")

    print()

def apply_preset(version_dir, preset_name, create_backup=True):
    """Apply a preset to a version directory."""
    # Check built-in presets first
    if preset_name in BUILTIN_PRESETS:
        preset = BUILTIN_PRESETS[preset_name]
    else:
        # Check custom presets
        custom_path = os.path.join(PRESETS_DIR, f"{preset_name}.json")
        if not os.path.exists(custom_path):
            print(f"{C.RED}Preset not found: {preset_name}{C.RESET}")
            print(f"{C.DIM}Run 'presets' to see available presets.{C.RESET}")
            return False
        try:
            with open(custom_path, "r", encoding="utf-8") as f:
                preset = json.load(f)
        except (json.JSONDecodeError, OSError) as e:
            print(f"{C.RED}Error loading preset: {e}{C.RESET}")
            return False

    flags_to_apply = preset.get("flags", {})
    if not flags_to_apply:
        print(f"{C.YELLOW}Preset has no flags.{C.RESET}")
        return False

    # Merge with existing flags (preset overwrites)
    current = read_fflags(version_dir)
    current.update(flags_to_apply)

    write_fflags(version_dir, current, create_backup=create_backup)

    print(f"{C.GREEN}Applied preset '{preset_name}' ({len(flags_to_apply)} flags){C.RESET}")
    for key, value in sorted(flags_to_apply.items()):
        print(f"  {C.CYAN}{key}{C.RESET} = {C.YELLOW}{value}{C.RESET}")

    return True

# ---------------------------------------------------------------------------
# CLI argument parsing
# ---------------------------------------------------------------------------

def parse_target(args):
    """Parse --target option from args."""
    target = "player"
    filtered = []
    i = 0
    while i < len(args):
        if args[i] == "--target" and i + 1 < len(args):
            target = args[i + 1]
            i += 2
        elif args[i] == "--no-backup":
            # Handled by caller
            filtered.append(args[i])
            i += 1
        else:
            filtered.append(args[i])
            i += 1
    return target, filtered

def has_no_backup(args):
    return "--no-backup" in args

def main():
    args = sys.argv[1:]

    if not args or args[0] in ("-h", "--help", "help"):
        print(__doc__)
        return

    command = args[0]
    rest = args[1:]

    # Filter out --no-backup from rest
    no_backup = has_no_backup(rest)
    rest = [a for a in rest if a != "--no-backup"]

    # Parse --target
    target, rest = parse_target(rest)

    # Find version directories
    version_dirs = find_version_dirs(target)

    if command == "info":
        print_info(version_dirs)
        return

    if not version_dirs:
        print(f"{C.RED}No Roblox installation found.{C.RESET}")
        print(f"{C.DIM}Expected at: {ROBLOX_VERSIONS_DIR}{C.RESET}")
        print(f"{C.DIM}Make sure Roblox is installed.{C.RESET}")
        return

    if command == "list":
        for vd in version_dirs:
            flags = read_fflags(vd["path"])
            print_fflags_table(flags, f"{os.path.basename(vd['path'])} ({vd['type']})")

    elif command == "dump":
        for vd in version_dirs:
            dump_path = dump_fflags(vd["path"])
            if dump_path:
                print(f"{C.GREEN}Dumped to: {dump_path}{C.RESET}")

    elif command == "set":
        if len(rest) < 2:
            print(f"{C.RED}Usage: set <key> <value>{C.RESET}")
            return
        key = rest[0]
        value = rest[1]
        # Auto-quote if the value looks like it should be a string
        if key.startswith("FFlag") or key.startswith("FBool"):
            value = "True" if value.lower() in ("true", "1", "yes") else "False"
        for vd in version_dirs:
            flags = read_fflags(vd["path"])
            flags[key] = value
            write_fflags(vd["path"], flags, create_backup=not no_backup)
            print(f"{C.GREEN}Set {C.CYAN}{key}{C.GREEN} = {C.YELLOW}{value}{C.RESET}")
            print(f"{C.DIM}  in {os.path.basename(vd['path'])}{C.RESET}")

        if is_roblox_running():
            print(f"\n{C.YELLOW}⚠ Roblox is running — restart for changes to take effect.{C.RESET}")

    elif command == "del":
        if len(rest) < 1:
            print(f"{C.RED}Usage: del <key>{C.RESET}")
            return
        key = rest[0]
        for vd in version_dirs:
            flags = read_fflags(vd["path"])
            if key not in flags:
                print(f"{C.YELLOW}Flag not found: {key}{C.RESET}")
                continue
            del flags[key]
            write_fflags(vd["path"], flags, create_backup=not no_backup)
            print(f"{C.GREEN}Deleted {C.CYAN}{key}{C.RESET}")
            print(f"{C.DIM}  from {os.path.basename(vd['path'])}{C.RESET}")

        if is_roblox_running():
            print(f"\n{C.YELLOW}⚠ Roblox is running — restart for changes to take effect.{C.RESET}")

    elif command == "clear":
        for vd in version_dirs:
            path = get_settings_path(vd["path"])
            if os.path.exists(path):
                if not no_backup:
                    backup_fflags(vd["path"])
                os.remove(path)
                print(f"{C.GREEN}Cleared all FFlags from {os.path.basename(vd['path'])}{C.RESET}")
            else:
                print(f"{C.DIM}No settings file in {os.path.basename(vd['path'])}{C.RESET}")

        if is_roblox_running():
            print(f"\n{C.YELLOW}⚠ Roblox is running — restart for changes to take effect.{C.RESET}")

    elif command == "watch":
        watch_mode(version_dirs)

    elif command == "import":
        if len(rest) < 1:
            print(f"{C.RED}Usage: import <file>{C.RESET}")
            return
        import_path = rest[0]
        if not os.path.exists(import_path):
            print(f"{C.RED}File not found: {import_path}{C.RESET}")
            return
        try:
            with open(import_path, "r", encoding="utf-8") as f:
                imported = json.load(f)
            if not isinstance(imported, dict):
                print(f"{C.RED}File must contain a JSON object{C.RESET}")
                return
        except json.JSONDecodeError as e:
            print(f"{C.RED}Invalid JSON: {e}{C.RESET}")
            return

        for vd in version_dirs:
            current = read_fflags(vd["path"])
            current.update(imported)
            write_fflags(vd["path"], current, create_backup=not no_backup)
            print(f"{C.GREEN}Imported {len(imported)} flags into {os.path.basename(vd['path'])}{C.RESET}")

        if is_roblox_running():
            print(f"\n{C.YELLOW}⚠ Roblox is running — restart for changes to take effect.{C.RESET}")

    elif command == "export":
        if len(rest) < 1:
            print(f"{C.RED}Usage: export <file>{C.RESET}")
            return
        export_path = rest[0]
        # Merge all version dirs
        all_flags = {}
        for vd in version_dirs:
            flags = read_fflags(vd["path"])
            all_flags.update(flags)

        with open(export_path, "w", encoding="utf-8") as f:
            json.dump(all_flags, f, indent=4, sort_keys=True)
            f.write("\n")
        print(f"{C.GREEN}Exported {len(all_flags)} flags to {export_path}{C.RESET}")

    elif command == "backup":
        for vd in version_dirs:
            path = get_settings_path(vd["path"])
            if os.path.exists(path):
                backup_path = backup_fflags(vd["path"])
                print(f"{C.GREEN}Backup created: {backup_path}{C.RESET}")
            else:
                print(f"{C.YELLOW}No settings file in {os.path.basename(vd['path'])}{C.RESET}")

    elif command == "restore":
        if len(rest) < 1:
            # List available backups
            backups = list_backups()
            if not backups:
                print(f"{C.YELLOW}No backups found in {BACKUP_DIR}{C.RESET}")
                return
            print(f"\n{C.BOLD}{C.BLUE}Available Backups{C.RESET}\n")
            for i, path in enumerate(backups):
                name = os.path.basename(path)
                mtime = datetime.fromtimestamp(os.path.getmtime(path)).strftime("%Y-%m-%d %H:%M:%S")
                print(f"  {C.CYAN}{i + 1}.{C.RESET} {name}  {C.DIM}({mtime}){C.RESET}")
            print(f"\n  Usage: restore <backup-file-or-number>{C.RESET}\n")
            return

        arg = rest[0]
        backups = list_backups()
        if arg.isdigit():
            idx = int(arg) - 1
            if idx < 0 or idx >= len(backups):
                print(f"{C.RED}Invalid backup number.{C.RESET}")
                return
            backup_path = backups[idx]
        else:
            backup_path = arg
            if not os.path.isabs(backup_path):
                backup_path = os.path.join(BACKUP_DIR, backup_path)

        for vd in version_dirs:
            if restore_fflags(vd["path"], backup_path):
                print(f"{C.GREEN}Restored to {os.path.basename(vd['path'])}{C.RESET}")

        if is_roblox_running():
            print(f"\n{C.YELLOW}⚠ Roblox is running — restart for changes to take effect.{C.RESET}")

    elif command == "presets":
        list_presets()

    elif command == "apply":
        if len(rest) < 1:
            print(f"{C.RED}Usage: apply <preset-name>{C.RESET}")
            return
        preset_name = rest[0]
        for vd in version_dirs:
            apply_preset(vd["path"], preset_name, create_backup=not no_backup)
            print(f"{C.DIM}  in {os.path.basename(vd['path'])}{C.RESET}")

        if is_roblox_running():
            print(f"\n{C.YELLOW}⚠ Roblox is running — restart for changes to take effect.{C.RESET}")

    else:
        print(f"{C.RED}Unknown command: {command}{C.RESET}")
        print(f"{C.DIM}Run 'python fflags.py help' for usage.{C.RESET}")


if __name__ == "__main__":
    main()
