# Monitor Handoff for Omarchy

Temporarily disconnect a selected monitor from Hyprland so the display can be switched to another computer, then reconnect it with one click.

## Features

- Left-click to choose a monitor from the displays detected by Hyprland.
- Right-click the bar icon to disconnect or reconnect the selected monitor.
- Persists the selected output in Omarchy's `shell.json`.
- Refuses to disconnect the last active monitor.
- Restores the user's own resolution, refresh rate, position, and scale from `monitors.lua`.
- Uses Hyprland's Lua runtime API introduced with the non-legacy configuration parser.

## Install

```bash
omarchy plugin add https://github.com/PedroSilvaAlves/omarchy-monitor-handoff --enable --yes
omarchy bar put pedrosilvaalves.monitor-handoff --before omarchy.clock
```

Left-click the new bar icon and select the display you want to hand off.

You can also configure an output from the command line:

```bash
omarchy bar set pedrosilvaalves.monitor-handoff monitor DP-2
```

## Requirements

- Omarchy Shell with third-party bar-widget support
- Hyprland using Lua configuration
- `bash` and `jq` (included with Omarchy)

## How reconnecting works

Hyprland runtime Lua monitor rules accumulate. A later enabled rule does not reliably override an earlier `disabled = true` rule. Reconnecting therefore runs `hyprctl reload`, which removes the temporary rule and reapplies the user's existing `~/.config/hypr/monitors.lua` configuration.

## License

MIT
