#!/usr/bin/env python3
"""
Usage:
  python3 parse_presets.py list                        # List all presets as "name|platform"
  python3 parse_presets.py platform <preset_name>      # Get platform of a preset
  python3 parse_presets.py is_android <preset_name>    # Check if preset is Android (exit 0 = true)
  python3 parse_presets.py has_android                 # Check if ANY preset is Android (exit 0 = true)
  python3 parse_presets.py get <preset_name> <key>     # Get a specific option value
  python3 parse_presets.py export_format <preset_name> # Get export format: apk or aab
  python3 parse_presets.py keystore <preset_name> <debug|release> # Get keystore path
  python3 parse_presets.py all_android                 # List all Android preset names

Exit codes:
  0 = success / true
  1 = not found / false
  2 = usage error
"""

import sys
import os
import re

PRESETS_FILE = os.environ.get("PRESETS_FILE", "export_presets.cfg")


def parse_presets(filepath):
    """
    Parse export_presets.cfg into a list of dicts.
    Each dict has 'name', 'platform', and 'options' (dict of key->value).
    """
    presets = []
    current_preset = None
    in_options = False

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: {filepath} not found.", file=sys.stderr)
        sys.exit(2)

    for line in lines:
        line = line.rstrip("\n").rstrip("\r")

        # New preset header: [preset.0], [preset.1], etc.
        if re.match(r"^\[preset\.\d+\]$", line):
            if current_preset is not None:
                presets.append(current_preset)
            current_preset = {"name": "", "platform": "", "options": {}}
            in_options = False
            continue

        # Preset options section
        if re.match(r"^\[preset\.\d+\.options\]$", line):
            in_options = True
            continue

        # Skip empty lines and comments
        if not line.strip() or line.strip().startswith(";"):
            continue

        # Parse key=value
        if current_preset is not None and "=" in line:
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"')

            if not in_options:
                # Top-level preset fields
                if key == "name":
                    current_preset["name"] = value
                elif key == "platform":
                    current_preset["platform"] = value
            else:
                # Options fields
                current_preset["options"][key] = value

    # Don't forget the last preset
    if current_preset is not None:
        presets.append(current_preset)

    return presets


def find_preset(presets, name):
    """Find a preset by name (case-sensitive)."""
    for p in presets:
        if p["name"] == name:
            return p
    return None


def cmd_list(presets):
    """Print all presets as name|platform."""
    for p in presets:
        if p["name"] and p["platform"]:
            print(f"{p['name']}|{p['platform']}")


def cmd_platform(presets, name):
    """Print platform of a named preset."""
    p = find_preset(presets, name)
    if not p:
        print(f"Error: Preset '{name}' not found.", file=sys.stderr)
        sys.exit(1)
    print(p["platform"])


def cmd_is_android(presets, name):
    """Exit 0 if named preset is Android, 1 otherwise."""
    p = find_preset(presets, name)
    if p and p["platform"] == "Android":
        sys.exit(0)
    sys.exit(1)


def cmd_has_android(presets):
    """Exit 0 if ANY preset is Android, 1 otherwise."""
    for p in presets:
        if p["platform"] == "Android":
            sys.exit(0)
    sys.exit(1)


def cmd_all_android(presets):
    """Print names of all Android presets."""
    found = False
    for p in presets:
        if p["platform"] == "Android":
            print(p["name"])
            found = True
    if not found:
        sys.exit(1)


def cmd_get(presets, name, key):
    """Get a specific option value from a preset."""
    p = find_preset(presets, name)
    if not p:
        print(f"Error: Preset '{name}' not found.", file=sys.stderr)
        sys.exit(1)
    value = p["options"].get(key, "")
    print(value)


def cmd_export_format(presets, name):
    """
    Print export format for Android preset: 'apk' or 'aab'.
    Godot 3 uses custom_build/export_format, Godot 4 uses gradle_build/export_format.
    0 = APK, 1 = AAB
    """
    p = find_preset(presets, name)
    if not p:
        print(f"Error: Preset '{name}' not found.", file=sys.stderr)
        sys.exit(1)

    # Try Godot 4 key first, fallback to Godot 3
    fmt = p["options"].get("gradle_build/export_format") or p["options"].get(
        "custom_build/export_format", "0"
    )

    print("aab" if fmt.strip() == "1" else "apk")


def cmd_keystore(presets, name, keystore_type):
    if keystore_type not in ("debug", "release"):
        print("Error: keystore type must be 'debug' or 'release'", file=sys.stderr)
        sys.exit(2)

    p = find_preset(presets, name)
    if not p:
        print(f"Error: Preset '{name}' not found.", file=sys.stderr)
        sys.exit(1)

    # Keystore hanya relevan untuk Android
    if p["platform"] != "Android":
        print("")
        sys.exit(0)

    default = "debug.keystore" if keystore_type == "debug" else "release.keystore"
    path = p["options"].get(f"keystore/{keystore_type}", "").replace("res://", "")
    print(path if path else default)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)

    presets = parse_presets(PRESETS_FILE)
    cmd = sys.argv[1]

    if cmd == "list":
        cmd_list(presets)

    elif cmd == "platform" and len(sys.argv) == 3:
        cmd_platform(presets, sys.argv[2])

    elif cmd == "is_android" and len(sys.argv) == 3:
        cmd_is_android(presets, sys.argv[2])

    elif cmd == "has_android":
        cmd_has_android(presets)

    elif cmd == "all_android":
        cmd_all_android(presets)

    elif cmd == "get" and len(sys.argv) == 4:
        cmd_get(presets, sys.argv[2], sys.argv[3])

    elif cmd == "export_format" and len(sys.argv) == 3:
        cmd_export_format(presets, sys.argv[2])

    elif cmd == "keystore" and len(sys.argv) == 4:
        cmd_keystore(presets, sys.argv[2], sys.argv[3])

    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
