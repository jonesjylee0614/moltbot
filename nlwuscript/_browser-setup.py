#!/usr/bin/env python3
"""Enable browser relay in OpenClaw config for Chrome extension connectivity."""
import json
import pathlib
import sys


def load_json(p: pathlib.Path) -> dict:
    if p.exists():
        return json.loads(p.read_text())
    return {}


def save_json(p: pathlib.Path, data: dict):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def configure_browser(config_path: pathlib.Path):
    cfg = load_json(config_path)

    browser = cfg.setdefault("browser", {})
    browser["enabled"] = True
    # Default profile is 'chrome' (extension relay)
    browser.setdefault("defaultProfile", "chrome")

    save_json(config_path, cfg)
    print(f"  [OK] {config_path}")


def main():
    home = pathlib.Path.home()
    updated = 0

    for profile in [".openclaw-dev", ".openclaw"]:
        config_path = home / profile / "openclaw.json"
        if config_path.exists():
            configure_browser(config_path)
            updated += 1
        else:
            print(f"  [SKIP] {config_path} (not found)")

    if updated == 0:
        print("[ERROR] No openclaw config files found. Run 'bot init' first.")
        sys.exit(1)

    # Verify relay port config
    for profile in [".openclaw-dev", ".openclaw"]:
        config_path = home / profile / "openclaw.json"
        if not config_path.exists():
            continue
        cfg = json.loads(config_path.read_text())
        gw_port = cfg.get("gateway", {}).get("port", 18789)
        relay_port = gw_port + 3  # gateway + 3 = relay
        control_port = gw_port + 2  # gateway + 2 = control
        print(f"\n  [{profile}]")
        print(f"  Gateway port:       {gw_port}")
        print(f"  Browser control:    {control_port}")
        print(f"  Extension relay:    {relay_port}")

    print("\n[DONE] Browser relay enabled.")
    print("Restart Gateway (bot full) for changes to take effect.")
    print("Chrome extension should connect to http://127.0.0.1:18792/")


if __name__ == "__main__":
    main()
