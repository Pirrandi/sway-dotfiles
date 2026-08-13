#!/usr/bin/env python3
"""Waybar custom/claude module: shows Claude Code plan usage percentage
(current session and current week), via `claude -p "/usage"`."""
import json
import os
import re
import subprocess

CLAUDE_BIN = os.path.expanduser("~/.local/bin/claude")
ICON = ""  # nf-fa-robot

try:
    result = subprocess.run(
        [CLAUDE_BIN, "-p", "/usage"],
        capture_output=True,
        text=True,
        timeout=20,
    )
    output = result.stdout
except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
    output = ""

session_match = re.search(r"Current session:\s*(\d+)%", output)
week_match = re.search(r"Current week \(all models\):\s*(\d+)%", output)

if session_match and week_match:
    session, week = session_match.group(1), week_match.group(1)
    text = f"{ICON}  {session}%/{week}%"
    tooltip = f"Session: {session}% used\nWeek (all models): {week}% used"
else:
    text = f"{ICON} --"
    tooltip = "Claude usage unavailable"

print(json.dumps({"text": text, "tooltip": tooltip}))
