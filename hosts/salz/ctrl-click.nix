{ pkgs, username, ... }:
let
  # Ctrl + physical trackpad click = right click, while this flag exists
  # (toggled with Fn+F7). Design notes: docs/salz.md.
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
    remapped = False
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

  # User-owned so the Hyprland toggle can flip the flag without root.
  systemd.tmpfiles.rules = [ "d /var/lib/ctrl-click 0755 ${username} users -" ];

  systemd.services.ctrl-click = {
    description = "Ctrl + trackpad click = right click";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      ExecStart = ctrlClick;
      Restart = "always";
      RestartSec = 2;
    };
  };
}
