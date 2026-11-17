# salz: MacBook Pro M1 Max on Asahi

## Kernel, firmware, boot

- `inputs.apple-silicon` provides the Asahi kernel, Mesa and firmware
  handling. It sets `boot.kernelPackages` itself.
- Wi-Fi and Bluetooth calibration firmware is per-machine data that the Asahi
  installer left in `/boot/vendorfw`. It is read at build time and never
  committed (the repo is public), so every build needs `--impure`.
  `peripheralFirmwareDirectory` is set explicitly because the module's own
  lookup uses `builtins.pathExists`, which returns null under pure evaluation
  and then fails with a misleading "firmware location appears incorrect".
- U-Boot chainloads systemd-boot from the EFI partition.
  `canTouchEfiVariables` stays false.
- `asahi-nvram.nix` mutes the boot chime through the `system:StartupMute`
  NVRAM key. It reads before it writes, because the tool rewrites the entry
  on every write and NVRAM is NOR flash with a finite number of erase cycles.
- NetworkManager uses the iwd backend, which handles the Broadcom chip's WPA3.

## Keyboard

- `hid_apple fnmode=2`: the top row sends media and brightness keys, and
  Fn+F-key sends the plain F-key. Hyprland can therefore bind the XF86
  symbols directly:

  | Keys  | Keysym          | Action                                      |
  | ----- | --------------- | ------------------------------------------- |
  | Fn+F3 | `XF86LaunchA`   | toggle disable-while-typing                 |
  | Fn+F4 | `XF86Search`    | enable or disable the trackpad              |
  | Fn+F7 | `XF86AudioPrev` | toggle Ctrl+click = right click             |

- The power button is the Touch ID key next to F12 and easy to hit, so logind
  ignores it. `fn-power.nix` runs a small evdev daemon instead: Fn+Power held
  for 3 seconds powers off, Power alone types Space. A compositor bind cannot
  do this, because Fn and Power are on two different evdev devices (the SPI
  keyboard and the SMC). The daemon watches the SMC device and reads the
  keyboard's live key state when Power goes down. Holding the button long
  enough still forces a firmware power-off.

## Trackpad

- **Disabling it (Fn+F4)** writes the kernel `inhibited` flag of the input
  device. Hyprland's per-device `enabled = false` only detached the pointer:
  the physical click still counted as held and swallowed mouse clicks. A udev
  rule in `configuration.nix` gives the user write access to the flag.
- **Ctrl+click = right click** (`ctrl-click.nix`), like macOS, off by
  default. Only a physical click of the built-in trackpad is affected. Taps
  are synthesised by libinput and produce no button event to catch, and
  external mice are untouched.
  - To swallow the left click the daemon has to grab the trackpad, so it
    replays everything through a uinput clone. The clone keeps the bus type
    and vendor/product IDs, so libinput still applies its Apple touchpad
    quirks and disable-while-typing pairing.
  - The right click comes from a second, tiny virtual mouse. The trackpad is
    a clickpad, and libinput drops any non-left button from a clickpad.
  - Ctrl is still held when the right click lands, so apps see
    Ctrl+right-click. That is why Hyprland also binds `SUPER CTRL, mouse:273`
    for resizing.
  - The toggle is the file `/var/lib/ctrl-click/on`, checked on every press,
    in a user-owned directory so it survives reboots and needs no root.
  - Fn+F4 still works: it inhibits the physical device by name, which
    silences the grab and with it the clone.
  - If the daemon crashes the grab is released and the trackpad behaves
    normally until systemd restarts it.

## Bluetooth

- The controller (bcm4377) and its firmware come from the Asahi side;
  `modules/system/bluetooth.nix` only adds BlueZ.
- `Experimental = true` turns on the BlueZ battery provider. Without it
  UPower sees no charge level for headphones or mice.
- `FastConnectable` keeps the adapter listening for AirPods, which drop the
  link when idle, so they reconnect on their own. It costs a little idle power.
- `blueman-manager` is used because it is a normal window; the Quickshell bar
  has no system tray. The NixOS module does not autostart the tray applet.
- `adwaita-icon-theme` is installed because Blueman asks for freedesktop
  device icons that the bare `hicolor` theme does not have.

## Other

- The Glorious Model O udev rule is shipped as a package rather than through
  `extraRules`: `uaccess` is applied in `73-seat-late`, and `extraRules`
  lands in `99-local`, which is too late.
- SDDM runs its greeter on Wayland with the `pixel-hollowknight` theme. The
  theme repo is ~570 MB, so only that theme is fetched (sparse checkout).
- `xwayland.force_zero_scaling` is off here: it collides with Steam's own
  `-forcedesktopscaling` and glitches the web helper windows.
