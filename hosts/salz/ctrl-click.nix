{ pkgs, username, ... }:
let
  # Ctrl + physical trackpad click = right click, like macOS. Only the
  # built-in trackpad's click is affected: external mice, and taps (which
  # libinput synthesises, there is no button event to catch), keep normal
  # Ctrl+click.
  #
  # Ctrl lives on the keyboard and the click on the trackpad, two evdev
  # devices, so no compositor bind can tell "trackpad click" from "mouse
  # click". Same approach as fn-power.nix: read the keyboard's live key state
  # when the button goes down.
  #
  # To swallow the left click the trackpad has to be grabbed, so everything
  # it sends is replayed through a uinput clone. The clone keeps the bus
  # (spi) and vendor/product IDs, so libinput still applies its Apple
  # touchpad quirks (palm size, size hint) and disable-while-typing pairing.
  # The right click itself comes from a separate tiny virtual mouse: the
  # trackpad is a clickpad, and libinput drops any non-left button event
  # from a clickpad as a kernel bug.
  #
  # Ctrl is still physically held when the right click lands, so apps see
  # Ctrl+right-click; in practice that opens the normal context menu.
  #
  # Toggle, off by default: only while `flag` exists does Ctrl+click become
  # a right click; otherwise it stays a normal Ctrl+left click.
  # Checked on every press, so flipping it (Fn+F7, binds.nix) applies
  # at once; it lives in /var/lib so the choice survives reboots.
  #
  # Fn+F4 (binds.nix) keeps working: it inhibits the *physical* device by its
  # exact name, which silences this daemon's grab and therefore the clone.
  flag = "/var/lib/ctrl-click/on";

  ctrlClick = pkgs.writers.writePython3 "ctrl-click" {
    libraries = [ pkgs.python3Packages.evdev ];
  } ''
    import os
    import evdev
    from evdev import ecodes

    CTRL = {ecodes.KEY_LEFTCTRL, ecodes.KEY_RIGHTCTRL}
    ON_FLAG = "${flag}"


    def find(name):
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            if dev.name == name:
                return dev
            dev.close()
        raise SystemExit(f"input device not found: {name}")


    pad = find("Apple SPI Trackpad")
    keyboard = find("Apple SPI Keyboard")

    clone = evdev.UInput.from_device(
        pad,
        name="Apple SPI Trackpad (ctrl-click)",
        vendor=pad.info.vendor,
        product=pad.info.product,
        version=pad.info.version,
        bustype=pad.info.bustype,
        input_props=pad.input_props(),
    )
    rbutton = evdev.UInput(
        {
            ecodes.EV_KEY: [ecodes.BTN_LEFT, ecodes.BTN_RIGHT],
            ecodes.EV_REL: [ecodes.REL_X, ecodes.REL_Y],
        },
        name="ctrl-click right button",
    )


    def right(value):
        rbutton.write(ecodes.EV_KEY, ecodes.BTN_RIGHT, value)
        rbutton.syn()


    pad.grab()
    remapped = False  # the current press became a right click
    try:
        for ev in pad.read_loop():
            if ev.type == ecodes.EV_KEY and ev.code == ecodes.BTN_LEFT:
                if (ev.value == 1 and CTRL & set(keyboard.active_keys())
                        and os.path.exists(ON_FLAG)):
                    remapped = True
                    right(1)
                    continue
                if ev.value == 0 and remapped:
                    remapped = False
                    right(0)
                    continue
            clone.write_event(ev)
    finally:
        if remapped:
            right(0)
        pad.ungrab()
  '';
in {
  hardware.uinput.enable = true;

  # User-owned so the Hyprland toggle can create/remove the flag without root.
  systemd.tmpfiles.rules = [ "d /var/lib/ctrl-click 0755 ${username} users -" ];

  systemd.services.ctrl-click = {
    description = "Ctrl + trackpad click = right click";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      ExecStart = ctrlClick;
      # A crash releases the grab, so the trackpad falls back to normal
      # behaviour until the restart.
      Restart = "always";
      RestartSec = 2;
    };
  };
}
