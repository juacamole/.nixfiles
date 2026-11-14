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
    };
  };

  # Terminal pairing/connect UI. Deliberately not blueman: that wants a system
  # tray to be useful, and the bar is quickshell, which has none.
  # `bluetoothctl` also ships with BlueZ for scripted use.
  environment.systemPackages = [ pkgs.bluetui ];
}
