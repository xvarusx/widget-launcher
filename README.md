# Quickshell Widget Launcher

A widget library and process manager for Quickshell on Omarchy / Hyprland.

## Features

- Discovers named Quickshell configurations in ~/.config/quickshell/ (folders containing shell.qml).
- PNG, WebP and SVG previews, with a generated screenshot fallback for running widgets.
- Search by name, category and description.
- Grid and list layouts.
- Running / stopped status, launch, stop and restart actions.
- Persistent favorites and inferred or metadata-defined categories.
- Reads the active Omarchy palette from ~/.local/state/omarchy/current/theme/colors.toml.
- Hyprland global shortcut and Quickshell IPC commands.
- Settings stored under $XDG_STATE_HOME/quickshell/widget-launcher/.

## Requirements

- Quickshell 0.3.2 or newer.
- Omarchy with Hyprland (theme integration and global shortcuts).
- Python 3.11+ (standard library only).
- hyprctl and grim for automatic screenshots of already-running widgets.

The launcher remains usable without grim; missing screenshots use a placeholder.

## Install

Clone this repository as a named Quickshell configuration:

~~~bash
git clone https://github.com/xvarusx/widget-launcher.git ~/.config/quickshell/widget-launcher
~~~

If it is already installed:

~~~bash
git -C ~/.config/quickshell/widget-launcher pull --ff-only
~~~

Start it:

~~~bash
qs -c widget-launcher
~~~

## Widget folder convention

Each widget is a direct child of ~/.config/quickshell/ and contains shell.qml:

~~~text
~/.config/quickshell/
├── widget-launcher/
│   ├── shell.qml
│   ├── services/
│   ├── ui/
│   └── scripts/
├── music-player/
│   ├── shell.qml
│   ├── preview.webp
│   └── metadata.json
└── system-monitor/
    └── shell.qml
~~~

Optional metadata.json:

~~~json
{
  "name": "Music Player",
  "description": "Desktop music controller",
  "category": "Media",
  "preview": "preview.webp"
}
~~~

Supported inferred categories: System, Media, Productivity, Appearance, Development, and Other. Metadata can override the category.

Preview discovery checks metadata preview first, then preview.png, preview.webp, preview.svg, and the equivalent screenshot.* names.

## Global shortcut

The shortcut uses Quickshell's Hyprland global-shortcuts integration. Add this to your Hyprland keybinds (commonly ~/.config/hypr/bindings.conf):

~~~ini
bind = SUPER, W, global, widget-launcher:toggle
~~~

Reload Hyprland:

~~~bash
hyprctl reload
~~~

Change SUPER + W to any free Hyprland shortcut by editing the bind. The Settings toggle enables or disables the launcher's response to the registered shortcut.

You can also control the launcher through Quickshell IPC:

~~~bash
qs ipc call widget-launcher toggle
qs ipc call widget-launcher show
qs ipc call widget-launcher hide
qs ipc call widget-launcher refresh
~~~

## Omarchy theme integration

The launcher reads the active generated palette at:

~/.local/state/omarchy/current/theme/colors.toml

It polls the palette while open, so switching Omarchy themes updates the launcher's surfaces, text, borders and accents without hardcoded theme palettes.

## Screenshot behavior

When a widget has no image preview and is already running, the backend finds its Quickshell window through hyprctl clients -j and captures that window's geometry using grim. Generated previews are stored in:

~/.cache/widget-launcher/previews/

The launcher does not start stopped widgets just to take screenshots. This avoids unexpectedly opening every widget or creating duplicate instances. Launch a widget and refresh the library to capture its preview.

## Settings and state

Settings and favorites are persisted outside the repository:

~/.local/state/quickshell/widget-launcher/settings.json

Generated screenshots are stored in the cache directory, not beside widget source files.
