{ pkgs, ... }:
let
  # Fn+Power held for 3 s powers off; Power alone types Space. The keys sit on
  # two evdev devices, so no compositor bind can chord them: this watches the
  # power key and reads the keyboard's live state when it goes down.
  fnPower = pkgs.writers.writePython3 "fn-power" {
    libraries = [ pkgs.python3Packages.evdev ];
  } ''
    import select
    import subprocess
    import time
    import evdev
    from evdev import ecodes

    HOLD = 3.0


    def find(name):
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            if dev.name == name:
                return dev
            dev.close()
        raise SystemExit(f"input device not found: {name}")


    power = find("Apple SMC power/lid events")
    keyboard = find("Apple SPI Keyboard")


    def fn_held():
        return ecodes.KEY_FN in keyboard.active_keys()


    def power_released(timeout):
        if not select.select([power], [], [], timeout)[0]:
            return False
        return any(ev.type == ecodes.EV_KEY and ev.code == ecodes.KEY_POWER
                   and ev.value == 0 for ev in power.read())


    def held_long_enough():
        deadline = time.monotonic() + HOLD
        while (left := deadline - time.monotonic()) > 0:
            if power_released(min(left, 0.1)) or not fn_held():
                return False
        return True


    space = evdev.UInput({ecodes.EV_KEY: [ecodes.KEY_SPACE]},
                         name="fn-power space")


    def send_space(value):
        space.write(ecodes.EV_KEY, ecodes.KEY_SPACE, value)
        space.syn()


    space_down = False
    for ev in power.read_loop():
        if ev.type != ecodes.EV_KEY or ev.code != ecodes.KEY_POWER:
            continue
        if ev.value == 1:
            if fn_held():
                if held_long_enough():
                    subprocess.run(["systemctl", "poweroff"])
            else:
                send_space(1)
                space_down = True
        elif ev.value == 0 and space_down:
            send_space(0)
            space_down = False
  '';
in {
  hardware.uinput.enable = true;

  # The power button is the Touch ID key next to F12; logind must not act on it.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
  };

  systemd.services.fn-power = {
    description = "Power off on Fn+Power, Space on bare Power";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    path = [ pkgs.systemd ];
    serviceConfig = {
      ExecStart = fnPower;
      Restart = "always";
      RestartSec = 2;
    };
  };
}
