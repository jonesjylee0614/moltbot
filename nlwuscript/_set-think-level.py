#!/usr/bin/env python3
"""Set thinkingDefault in both default and dev OpenClaw profiles."""
import json
import os
import pathlib
import sys

VALID = ["off", "minimal", "low", "medium", "high", "xhigh"]

if len(sys.argv) < 2:
    print(f"Usage: _set-think-level.py <{'|'.join(VALID)}>")
    sys.exit(1)

level = sys.argv[1].strip().lower()
if level not in VALID:
    print(f"Invalid level: {level}")
    print(f"Valid levels: {', '.join(VALID)}")
    sys.exit(1)

home = pathlib.Path.home()
updated = False

for suffix in ["", "-dev"]:
    p = home / f".openclaw{suffix}" / "openclaw.json"
    if not p.exists():
        continue
    cfg = json.loads(p.read_text())
    agents = cfg.setdefault("agents", {})
    defaults = agents.setdefault("defaults", {})
    defaults["thinkingDefault"] = level
    p.write_text(json.dumps(cfg, indent=2))
    os.chmod(p, 0o600)
    print(f"Set thinkingDefault={level} in {p}")
    updated = True

if not updated:
    print("No config files found to update.")
    sys.exit(1)

print(f"\nDone! Default thinking level: {level}")
print("Note: 对已有会话，可在 UI 中点 Thinking 下拉切换，或输入 /think <level>")
