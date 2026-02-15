#!/usr/bin/env python3
"""
Lock down Telegram bot to specific user IDs only.
Usage: python3 _tg-lockdown.py <your-telegram-user-id> [additional-ids...]

This sets dmPolicy to "allowlist" and groupPolicy to "disabled",
so only the specified user IDs can DM the bot, and groups are blocked.
"""
import json
import pathlib
import sys

def load_json(p: pathlib.Path) -> dict:
    if p.exists():
        try:
            return json.loads(p.read_text())
        except Exception:
            return {}
    return {}

def save_json(p: pathlib.Path, data: dict):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")

def lockdown(config_path: pathlib.Path, user_ids: list[str]):
    cfg = load_json(config_path)
    channels = cfg.setdefault("channels", {})
    telegram = channels.setdefault("telegram", {})

    # Set DM policy to allowlist — only listed IDs can DM
    telegram["dmPolicy"] = "allowlist"
    telegram["allowFrom"] = user_ids

    # Disable groups entirely
    telegram["groupPolicy"] = "disabled"

    save_json(config_path, cfg)
    print(f"[tg-lockdown] Updated: {config_path}")
    print(f"[tg-lockdown]   dmPolicy = allowlist")
    print(f"[tg-lockdown]   allowFrom = {user_ids}")
    print(f"[tg-lockdown]   groupPolicy = disabled")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 _tg-lockdown.py <your-telegram-user-id> [additional-ids...]")
        print()
        print("This locks down the Telegram bot so only specified users can DM it,")
        print("and groups are completely disabled.")
        print()
        print("To find your Telegram User ID, message @userinfobot in Telegram.")
        sys.exit(2)

    user_ids = sys.argv[1:]
    print(f"[tg-lockdown] Locking Telegram bot to user IDs: {user_ids}")

    profiles = [
        pathlib.Path.home() / ".openclaw" / "openclaw.json",
        pathlib.Path.home() / ".openclaw-dev" / "openclaw.json",
    ]

    for config_path in profiles:
        lockdown(config_path, user_ids)

    print()
    print("[tg-lockdown] Done! Only the specified users can DM the bot.")
    print("[tg-lockdown] Groups are disabled. Restart gateway to apply.")

if __name__ == "__main__":
    main()
