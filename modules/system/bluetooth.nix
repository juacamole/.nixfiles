{ pkgs, ... }: {
  # BlueZ stack. On salz the controller (bcm4377) is driven by the Asahi
  # kernel and its calibration blob comes from the vendor firmware cpio that
  # `hardware.asahi.extractPeripheralFirmware` unpacks — so `hci0` already
  # exists before this module does anything. All that was missing is BlueZ
  # itself plus bluetooth.service.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings.General = {
      # Enables the BlueZ Battery Provider API. Without it UPower reports no
      # charge level for headphones/mice, and the QS Battery widget only ever
      # sees the internal battery.
      Experimental = true;

      # Advertise both A2DP sink and source so the machine can play to
      # headphones and accept audio from a phone.
      ControllerMode = "dual";

      # AirPods drop the link aggressively when idle. This keeps the adapter
      # listening for their reconnect page, so putting them back in ears
      # reconnects instead of needing a manual connect. Costs a little idle
      # power on the controller.
      FastConnectable = true;
    };
  };

  # GUI manager: `blueman-manager` is a normal standalone window, so it works
  # without a system tray (the bar is quickshell, which has none). The NixOS
  # module only installs the package plus the blueman-mechanism D-Bus/polkit
  # service — it does not autostart the tray applet, which is what we want.
  services.blueman.enable = true;

  # Blueman renders each device with the icon BlueZ reports from its class of
  # device (e.g. `audio-headphones` for the AirPods). Those names live in the
  # freedesktop icon naming spec, which hicolor — the only theme a bare NixOS
  # installs — does not implement. Without a real theme every row falls back to
  # a broken-image placeholder and blueman logs `Failed to look up icon`.
  # GTK's default icon-theme name is already "Adwaita", so having the package
  # on the system icon path is enough; no gtk settings change is needed.
  environment.systemPackages = [ pkgs.adwaita-icon-theme ];

  # `bluetoothctl` also ships with BlueZ for scripted use.
}
