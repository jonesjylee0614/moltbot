#!/usr/bin/env python3
"""Enable all bundled plugins in OpenClaw config."""
import json
import os
import pathlib
import sys


def load_json(p: pathlib.Path) -> dict:
    if p.exists():
        return json.loads(p.read_text())
    return {}


def save_json(p: pathlib.Path, data: dict):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def discover_bundled_plugins(repo_root: pathlib.Path) -> list[dict]:
    """Discover all bundled plugins from the extensions/ directory."""
    ext_dir = repo_root / "extensions"
    plugins = []
    if not ext_dir.exists():
        return plugins
    for manifest_path in ext_dir.rglob("openclaw.plugin.json"):
        try:
            manifest = json.loads(manifest_path.read_text())
            plugin_id = manifest.get("id", manifest_path.parent.name)
            plugin_type = "unknown"
            if manifest.get("channel") or manifest.get("channels"):
                plugin_type = "channel"
            elif manifest.get("providerAuth"):
                plugin_type = "provider-auth"
            elif manifest.get("skill"):
                plugin_type = "skill"
            elif manifest.get("memory"):
                plugin_type = "memory"
            else:
                plugin_type = "tool"
            plugins.append({
                "id": plugin_id,
                "type": plugin_type,
                "name": manifest.get("displayName", plugin_id),
                "description": manifest.get("description", ""),
            })
        except Exception:
            continue
    return sorted(plugins, key=lambda p: (p["type"], p["id"]))


def enable_all_plugins(config_path: pathlib.Path, plugins: list[dict]):
    """Enable all plugins in the config file."""
    cfg = load_json(config_path)

    plugin_cfg = cfg.setdefault("plugins", {})
    entries = plugin_cfg.setdefault("entries", {})

    enabled_count = 0
    already_count = 0

    for plugin in plugins:
        pid = plugin["id"]
        entry = entries.setdefault(pid, {})
        if entry.get("enabled") is True:
            already_count += 1
        else:
            entry["enabled"] = True
            enabled_count += 1

    save_json(config_path, cfg)
    return enabled_count, already_count


def main():
    # Find repo root
    repo_root = None
    for candidate in [
        pathlib.Path(os.environ.get("REPO_ROOT", "")),
        pathlib.Path(__file__).resolve().parent.parent,
        pathlib.Path.cwd(),
    ]:
        if (candidate / "extensions").is_dir() and (candidate / "package.json").is_file():
            repo_root = candidate
            break

    if not repo_root:
        print("[ERROR] Cannot find repo root (extensions/ directory)")
        sys.exit(1)

    # Discover plugins
    plugins = discover_bundled_plugins(repo_root)
    if not plugins:
        print("[ERROR] No plugins found in extensions/")
        sys.exit(1)

    # Print discovered plugins
    print(f"Found {len(plugins)} bundled plugins:\n")

    type_labels = {
        "channel": "Channel (chat platform)",
        "provider-auth": "Provider Auth (model access)",
        "memory": "Memory",
        "skill": "Skill",
        "tool": "Tool / Utility",
        "unknown": "Other",
    }

    current_type = ""
    for p in plugins:
        if p["type"] != current_type:
            current_type = p["type"]
            label = type_labels.get(current_type, current_type)
            print(f"  [{label}]")
        desc = f" - {p['description']}" if p["description"] else ""
        print(f"    {p['id']:30s} {p['name']}{desc}")
    print()

    # Enable in both profiles
    home = pathlib.Path.home()
    total_enabled = 0
    total_already = 0

    for profile in [".openclaw-dev", ".openclaw"]:
        config_path = home / profile / "openclaw.json"
        if not config_path.exists():
            print(f"  [SKIP] {config_path} (not found)")
            continue
        enabled, already = enable_all_plugins(config_path, plugins)
        total_enabled += enabled
        total_already += already
        print(f"  [{profile}] Enabled {enabled} new, {already} already enabled")

    print(f"\n[DONE] All {len(plugins)} plugins enabled.")
    print("Restart Gateway (bot full) for changes to take effect.")
    print("\nNote: Channel plugins (telegram, discord, etc.) need tokens/config to actually connect.")
    print("Tool/utility plugins will be available immediately after restart.")


if __name__ == "__main__":
    main()
