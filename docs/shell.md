# The desktop shell (`modules/home/quickshell/`)

A Quickshell configuration named `kuan`: bar, launcher, notifications and
volume/brightness OSD.

## How it runs

- The QML in `config/` is copied into the store, so there is no hot reload.
  Edit, then `nix-switch`.
- It runs as the systemd user unit `quickshell`, not as a Hyprland
  `exec-once`. The unit restarts on a switch whenever `config/` changed.
- Widgets call `nmcli`, `wpctl`, `allam`, `idle-lock`, `battery-saver` and
  `kitty`. The unit sets `PATH` itself, because the user manager's PATH does
  not include the profiles.
- `qsctl <target> <function>` is the IPC entry point used by the Hyprland
  binds. Targets are declared in `shell.qml`: `launcher`, `notifications`,
  `osd`, `battery-saver`.

## Files

| File | Role |
| --- | --- |
| `shell.qml` | Entry point and IPC handlers. |
| `Theme.qml` | Colours, sizes, fonts, icon codepoints, animation timings. |
| `Slab.qml` | The one surface style: flat face, ink outline, hard shadow. |
| `StatusItem.qml`, `Icon.qml` | Building blocks for the status pill. |
| `Bar.qml` | Three clusters: workspaces + allam, clock, status pill. |
| `Workspaces`, `Clock`, `Memory`, `Volume`, `Network`, `Battery`, `IdleLockToggle`, `AllamWidget` | Bar widgets. |
| `BatterySaver`, `IdleLock`, `Allam` | Singletons that mirror state owned by a script or daemon. |
| `Launcher`, `Notifications`, `OSD` | Overlays. |

A new component must be added to `qmldir`.

## Look

Flat and opaque: solid surfaces, near-black outlines, hard offset shadows,
no blur or translucency. Fredoka is the only text face and tabler-icons
supplies the glyphs. Neither is in nixpkgs, so `default.nix` fetches pinned
files. The icon codepoints in `Theme.qml` belong to that exact tabler
version and are invisible in most tools; do not retype those lines.

The colours come from the wallpaper and are duplicated in
`modules/home/palette.nix` (`night`) for the lock screen.

## Flicker rules for the bar

These fix real glitches and apply to every bar widget.

- `renderType: Text.NativeRendering` on bar text.
- Never assign a property its current value. Guard every update from a poll
  (`if (x !== next) x = next`), and commit multi-part state once, after the
  process exits.
- Keep widths stable. Give text a fixed width from `TextMetrics` of its
  widest string; proportional digits otherwise resize the pill.
- Animate opacity, colour, position and width. Never animate the scale of
  NativeRendering text.
- Keep delegates alive. The workspace row always has ten slots and collapses
  the dead ones, instead of rebuilding the list.
- The clock is anchored to the centre of the panel, not placed by a layout,
  so the side clusters cannot push it.

## Notifications

- Remove a notification from `live` and `history` before its object is
  destroyed. A dead QObject left in a JS-array model crashes Qt.
- Assigning a new array to `live` recreates every card, so only the card
  matching `lastAdded` plays the entrance animation.
- Critical notifications stay until dismissed. `battery-warn` relies on that.
- The card uses a plain `Column`. A `ColumnLayout` there creates a size
  cycle and the wrapped text collapses to zero height.
- A delegate component must declare `required property var modelData`, or
  every binding on the notification is undefined.
- The `toggle-saver` action is handled inside the card, because most senders
  exit before the action signal could reach them.

## State scripts

`battery-saver` and `idle-lock` follow the same pattern. A shell script owns
a state file under `$XDG_STATE_HOME/quickshell/` and offers
`enable|disable|toggle|status|apply`. A oneshot user unit runs `apply` at
login. The QML singleton only calls the script and re-reads `status`, with a
30 second poll for changes made elsewhere.

- **battery-saver** (salz only) forces every monitor to 60 Hz with explicit
  mode strings, since Hyprland's `preferred` accepts no refresh override.
  Turning it off runs `hyprctl reload`, which restores the configured modes.
  Widgets also poll more slowly while it is on.
- **idle-lock** (`modules/home/hypridle.nix`) is the coffee cup in the bar.
  On: hypridle runs and locks after 10 minutes, and closing the lid
  suspends. Off (the default): hypridle is stopped and the `lid-awake` unit
  holds a lid-switch inhibitor, so closing the lid does nothing. hypridle
  must never be started from `exec-once`, or the toggle cannot see it.

## battery-warn (`modules/home/battery.nix`)

A timer checks the battery every minute and warns at 20, 10 and 5 percent.

- Each level closes the previous toast and sends a new one. Using
  `replaces_id` would update the toast in place without showing it again.
- It talks to D-Bus with `gdbus`. `notify-send --action` blocks until the
  toast closes, and critical toasts never close by themselves.
- The 20% warning waits while a window is fullscreen. The critical ones
  always show.
- When battery-saver exists and is off, the toast offers a button for it.
- The battery's sysfs name differs per machine, so each host sets
  `services.battery-warn.device` (default `BAT1`, salz `macsmc-battery`).
