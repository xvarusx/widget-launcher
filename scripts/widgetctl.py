#!/usr/bin/env python3
"""Widget discovery and process helper for the Quickshell Widget Launcher."""

from __future__ import annotations

import json
import os
import re
import signal
import shutil
import subprocess
import sys
import time
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None

CONFIG_ROOT = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "quickshell"
STATE_ROOT = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "quickshell/widget-launcher"
CACHE_ROOT = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "widget-launcher"
SETTINGS_FILE = STATE_ROOT / "settings.json"
PALETTE_FILE = Path.home() / ".local/state/omarchy/current/theme/colors.toml"
LAUNCHER_CONFIG = Path(__file__).resolve().parents[1].name

DEFAULT_SETTINGS = {
    "view_mode": "grid",
    "auto_refresh_seconds": 8,
    "auto_capture_previews": True,
    "global_shortcut_enabled": True,
    "window_opacity": 94,
}

CATEGORY_KEYWORDS = {
    "System": ("system", "monitor", "resource", "cpu", "memory", "network", "disk", "process"),
    "Media": ("music", "media", "player", "volume", "audio", "visualizer", "video"),
    "Productivity": ("calendar", "todo", "task", "note", "clock", "timer", "pomodoro"),
    "Appearance": ("wallpaper", "theme", "color", "appearance", "bar", "dock"),
    "Development": ("dev", "code", "git", "docker", "terminal", "editor"),
}


def emit(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=False))


def load_settings() -> dict:
    STATE_ROOT.mkdir(parents=True, exist_ok=True)
    settings = DEFAULT_SETTINGS.copy()
    try:
        saved = json.loads(SETTINGS_FILE.read_text(encoding="utf-8"))
        if isinstance(saved, dict):
            settings.update(saved)
    except (OSError, json.JSONDecodeError):
        pass

    if settings.get("view_mode") not in ("grid", "list"):
        settings["view_mode"] = "grid"
    settings.pop("favorites", None)
    settings.pop("show_favorites_first", None)
    try:
        settings["auto_refresh_seconds"] = max(0, min(60, int(settings["auto_refresh_seconds"])))
        settings["window_opacity"] = max(70, min(100, int(settings["window_opacity"])))
    except (TypeError, ValueError):
        settings.update(DEFAULT_SETTINGS)
    return settings


def save_settings(incoming: dict) -> dict:
    current = load_settings()
    current.update({key: value for key, value in incoming.items() if key in DEFAULT_SETTINGS})
    if current["view_mode"] not in ("grid", "list"):
        current["view_mode"] = "grid"
    current.pop("favorites", None)
    current.pop("show_favorites_first", None)
    current["auto_refresh_seconds"] = max(0, min(60, int(current["auto_refresh_seconds"])))
    current["window_opacity"] = max(70, min(100, int(current["window_opacity"])))
    STATE_ROOT.mkdir(parents=True, exist_ok=True)
    temporary = SETTINGS_FILE.with_suffix(".tmp")
    temporary.write_text(json.dumps(current, indent=2), encoding="utf-8")
    temporary.replace(SETTINGS_FILE)
    return current


def read_corner_radius() -> int:
    """Read the active Hyprland rounding value used by Omarchy."""
    try:
        result = subprocess.run(
            ["hyprctl", "-j", "getoption", "decoration:rounding"],
            capture_output=True, text=True, timeout=2, check=True,
        )
        payload = json.loads(result.stdout)
        value = payload.get("int", payload.get("float", 0))
        return max(0, min(64, int(float(value))))
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError, TypeError, ValueError):
        pass

    # Fallback for Omarchy's Lua config and older Hyprland config layouts.
    config_root = Path.home() / ".config/hypr"
    for filename in ("looknfeel.lua", "looknfeel.conf", "hyprland.conf"):
        try:
            raw = (config_root / filename).read_text(encoding="utf-8")
        except OSError:
            continue
        matches = re.findall(r"\\brounding\\s*=\\s*(\\d+(?:\\.\\d+)?)", raw)
        if matches:
            return max(0, min(64, int(float(matches[-1]))))
    return 0


def read_palette() -> dict:
    palette = {
        "background": "#171717", "dark_background": "#101010",
        "darker_background": "#090909", "lighter_background": "#262626",
        "foreground": "#f5f5f5", "dark_foreground": "#a3a3a3",
        "accent": "#89b4fa", "selection": "#343434", "muted": "#737373",
        "red": "#f38ba8", "green": "#a6e3a1", "blue": "#89b4fa",
    }
    try:
        raw = PALETTE_FILE.read_text(encoding="utf-8")
        if tomllib:
            values = tomllib.loads(raw)
        else:
            values = {
                key: value.strip().strip('"').strip("'")
                for key, value in re.findall(r"^\s*([a-z_]+)\s*=\s*([^\n#]+)", raw, re.M)
            }
        for key in palette:
            value = values.get(key)
            if isinstance(value, str) and re.fullmatch(r"#[0-9a-fA-F]{6,8}", value):
                palette[key] = value
    except (OSError, ValueError):
        pass
    palette["corner_radius"] = read_corner_radius()
    return palette


def process_table() -> dict[str, list[int]]:
    result: dict[str, list[int]] = {}
    proc = Path("/proc")
    if not proc.exists():
        return result

    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            pid = int(entry.name)
            args = (entry / "cmdline").read_bytes().decode(errors="ignore").split("\0")
            args = [arg for arg in args if arg]
            if not args or Path(args[0]).name not in ("qs", "quickshell"):
                continue
            for index, token in enumerate(args[:-1]):
                if token in ("-c", "--config"):
                    result.setdefault(args[index + 1], []).append(pid)
                    break
        except (OSError, ValueError, IndexError):
            continue
    return result


def category_for(name: str, metadata: dict) -> str:
    declared = metadata.get("category")
    if isinstance(declared, str) and declared.strip():
        normalized = declared.strip().lower()
        known = {
            "system": "System", "media": "Media", "productivity": "Productivity",
            "appearance": "Appearance", "development": "Development",
        }
        return known.get(normalized, declared.strip().title())

    haystack = name.lower().replace("_", "-")
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in haystack for keyword in keywords):
            return category
    return "Other"


def read_metadata(folder: Path) -> dict:
    for filename in ("metadata.json", "widget.json"):
        try:
            value = json.loads((folder / filename).read_text(encoding="utf-8"))
            if isinstance(value, dict):
                return value
        except (OSError, json.JSONDecodeError):
            continue
    return {}


def capture_hyprland_preview(config: str, pids: list[int]) -> str:
    if not pids:
        return ""
    output = CACHE_ROOT / "previews" / (config + ".png")
    if output.is_file() and output.stat().st_size > 0:
        return str(output)

    try:
        response = subprocess.run(
            ["hyprctl", "-j", "clients"], capture_output=True, text=True, timeout=2, check=True
        )
        clients = json.loads(response.stdout)
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        return ""

    for client in clients:
        if client.get("pid") not in set(pids):
            continue
        position, size = client.get("at"), client.get("size")
        if not (isinstance(position, list) and len(position) == 2 and
                isinstance(size, list) and len(size) == 2):
            continue
        try:
            x, y = (int(value) for value in position)
            width, height = (int(value) for value in size)
        except (TypeError, ValueError):
            continue
        if width < 40 or height < 40:
            continue
        output.parent.mkdir(parents=True, exist_ok=True)
        try:
            subprocess.run(
                ["grim", "-g", f"{x},{y} {width}x{height}", str(output)],
                capture_output=True, text=True, timeout=5, check=True
            )
            return str(output) if output.is_file() else ""
        except (OSError, subprocess.SubprocessError):
            return ""
    return ""


def autostart_unit(config: str) -> str:
    return f"widget-launcher-{config}.service"


def autostart_enabled(config: str) -> bool:
    unit = autostart_unit(config)
    try:
        result = subprocess.run(
            ["systemctl", "--user", "is-enabled", unit],
            capture_output=True, text=True, timeout=3,
        )
        return result.returncode == 0 and result.stdout.strip() == "enabled"
    except (OSError, subprocess.SubprocessError):
        return False


def set_autostart(config: str, enabled: bool) -> dict:
    folder = CONFIG_ROOT / config
    if not (folder / "shell.qml").is_file():
        return {"error": f"Configuration '{config}' was not found."}

    systemd_dir = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "systemd/user"
    systemd_dir.mkdir(parents=True, exist_ok=True)
    unit_name = autostart_unit(config)
    unit_path = systemd_dir / unit_name

    if enabled:
        qs_path = shutil.which("qs")
        if not qs_path:
            return {"error": "Could not find 'qs' in PATH; cannot create the startup service."}
        unit = (
            "[Unit]\\n"
            f"Description=Quickshell widget: {config}\\n"
            "After=graphical-session.target\\n"
            "PartOf=graphical-session.target\\n\\n"
            "[Service]\\n"
            "Type=simple\\n"
            f"ExecStart={qs_path} -c {config}\\n"
            "Restart=on-failure\\n"
            "RestartSec=2\\n\\n"
            "[Install]\\n"
            "WantedBy=default.target\\n"
        )
        temporary = unit_path.with_suffix(".tmp")
        temporary.write_text(unit, encoding="utf-8")
        temporary.replace(unit_path)
        commands = [
            ["systemctl", "--user", "daemon-reload"],
            ["systemctl", "--user", "enable", "--now", unit_name],
        ]
    else:
        commands = [
            ["systemctl", "--user", "disable", "--now", unit_name],
        ]

    for command in commands:
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=10)
        except (OSError, subprocess.SubprocessError) as error:
            return {"error": f"Could not update auto-start for '{config}': {error}"}
        if result.returncode != 0:
            detail = (result.stderr or result.stdout).strip()
            return {"error": detail or f"Command failed: {' '.join(command)}"}

    return {"ok": True, "autostart": enabled}


def scan() -> dict:
    settings = load_settings()
    running = process_table()
    widgets = []

    if CONFIG_ROOT.is_dir():
        for folder in sorted(CONFIG_ROOT.iterdir(), key=lambda item: item.name.casefold()):
            if not folder.is_dir() or folder.name == LAUNCHER_CONFIG:
                continue
            if not (folder / "shell.qml").is_file():
                continue

            metadata = read_metadata(folder)
            preview, preview_kind = "", ""
            requested = metadata.get("preview")
            candidates = [folder / requested] if isinstance(requested, str) and requested else []
            candidates.extend(folder / ("preview." + ext) for ext in ("png", "webp", "svg"))
            candidates.extend(folder / ("screenshot." + ext) for ext in ("png", "webp", "svg"))

            for candidate in candidates:
                try:
                    if candidate.is_file() and candidate.resolve().is_relative_to(folder.resolve()):
                        preview, preview_kind = str(candidate.resolve()), "image"
                        break
                except (OSError, ValueError):
                    continue

            pids = running.get(folder.name, [])
            if not preview and settings["auto_capture_previews"]:
                generated = capture_hyprland_preview(folder.name, pids)
                if generated:
                    preview, preview_kind = generated, "generated"

            widgets.append({
                "name": folder.name,
                "label": str(metadata.get("name") or folder.name.replace("-", " ").replace("_", " ").title()),
                "description": str(metadata.get("description") or ""),
                "category": category_for(folder.name, metadata),
                "path": str(folder),
                "preview": preview,
                "preview_kind": preview_kind,
                "running": bool(pids),
                "autostart": autostart_enabled(folder.name),
                "pids": pids,
            })

    return {"widgets": widgets, "settings": settings, "theme": read_palette()}


def launch(config: str) -> dict:
    if not (CONFIG_ROOT / config / "shell.qml").is_file():
        return {"error": f"Configuration '{config}' was not found."}
    if process_table().get(config):
        return {"ok": True, "already_running": True}
    try:
        subprocess.Popen(
            ["qs", "-c", config], stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True, close_fds=True,
        )
        return {"ok": True}
    except OSError as error:
        return {"error": f"Could not launch '{config}': {error}"}


def stop(config: str) -> dict:
    pids = process_table().get(config, [])
    if not pids:
        return {"ok": True, "already_stopped": True}
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        except PermissionError:
            return {"error": f"Permission denied while stopping process {pid}."}
    return {"ok": True}


def restart(config: str) -> dict:
    stopped = stop(config)
    if stopped.get("error"):
        return stopped
    deadline = time.monotonic() + 2.0
    while process_table().get(config) and time.monotonic() < deadline:
        time.sleep(0.1)
    if process_table().get(config):
        return {"error": f"'{config}' did not stop; restart was cancelled."}
    return launch(config)


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        emit({"error": "Expected scan, theme, launch, stop, restart, autostart-enable, autostart-disable, or settings-set."})
        return 2

    command = argv[1]
    if command == "scan":
        emit(scan())
        return 0
    if command == "theme":
        emit(read_palette())
        return 0
    if command == "settings-set":
        try:
            incoming = json.loads(argv[2])
            if not isinstance(incoming, dict):
                raise ValueError("Settings must be a JSON object.")
            emit({"settings": save_settings(incoming)})
            return 0
        except (IndexError, json.JSONDecodeError, ValueError, TypeError) as error:
            emit({"error": str(error)})
            return 2

    if command in ("autostart-enable", "autostart-disable"):
        if len(argv) < 3:
            emit({"error": f"{command} requires a configuration name."})
            return 2
        config = argv[2]
        if not re.fullmatch(r"[A-Za-z0-9_.+-]+", config):
            emit({"error": "Invalid widget configuration name."})
            return 2
        result = set_autostart(config, command == "autostart-enable")
        emit(result)
        return 1 if result.get("error") else 0

    if command in ("launch", "stop", "restart"):
        if len(argv) < 3:
            emit({"error": f"{command} requires a configuration name."})
            return 2
        config = argv[2]
        if not re.fullmatch(r"[A-Za-z0-9_.+-]+", config):
            emit({"error": "Invalid widget configuration name."})
            return 2
        result = {"launch": launch, "stop": stop, "restart": restart}[command](config)
        emit(result)
        return 1 if result.get("error") else 0

    emit({"error": f"Unknown command: {command}"})
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
