#!/usr/bin/env python3
"""
Configure Telegram bot channel in OpenClaw config files.
Usage: python3 _tg-setup.py <bot-token> [account-id]

This directly writes the telegram channel config + enables the telegram plugin,
bypassing the `channels add` command which requires the plugin registry to be
initialized with the channel plugin already enabled.
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

def configure_telegram(config_path: pathlib.Path, bot_token: str, account_id: str = "default"):
    cfg = load_json(config_path)

    # 1. Enable telegram plugin
    plugins = cfg.setdefault("plugins", {})
    entries = plugins.setdefault("entries", {})
    tg_plugin = entries.setdefault("telegram", {})
    tg_plugin["enabled"] = True

    # 2. Configure telegram channel
    channels = cfg.setdefault("channels", {})
    telegram = channels.setdefault("telegram", {})
    telegram["enabled"] = True

    if account_id == "default":
        # For default account, set botToken at the channel level
        telegram["botToken"] = bot_token
    else:
        # For non-default accounts, use the accounts sub-key
        accounts = telegram.setdefault("accounts", {})
        account = accounts.setdefault(account_id, {})
        account["botToken"] = bot_token

    save_json(config_path, cfg)
    print(f"[tg-setup] Updated: {config_path}")
    print(f"[tg-setup]   telegram.enabled = true")
    print(f"[tg-setup]   telegram plugin enabled = true")
    print(f"[tg-setup]   account = {account_id}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 _tg-setup.py <bot-token> [account-id]")
        print("  bot-token: Telegram Bot API token from @BotFather")
        print("  account-id: Account ID (default: 'default')")
        sys.exit(2)

    bot_token = sys.argv[1]
    account_id = sys.argv[2] if len(sys.argv) > 2 else "default"

    # Mask token in output
    masked = bot_token[:8] + "..." if len(bot_token) > 8 else "***"
    print(f"[tg-setup] Configuring Telegram bot (token: {masked})")

    # Configure in both default and dev profiles
    profiles = [
        pathlib.Path.home() / ".openclaw" / "openclaw.json",
        pathlib.Path.home() / ".openclaw-dev" / "openclaw.json",
    ]

    for config_path in profiles:
        configure_telegram(config_path, bot_token, account_id)

    print()
    print("[tg-setup] Done! Telegram channel configured.")
    print("[tg-setup] Next steps:")
    print("[tg-setup]   1. Start the gateway:  bot gateway  (or  bot full)")
    print("[tg-setup]   2. Check status:        bot tg-status")
    print("[tg-setup]   3. Send /start to your bot in Telegram")
    print("[tg-setup]   4. Approve pairing:     bot pair-list  →  bot pair-approve <code>")

if __name__ == "__main__":
    main()
