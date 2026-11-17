{ pkgs, inputs, username, ... }: {
  imports = [
    # Brings the Asahi kernel; never set boot.kernelPackages on this host.
    inputs.apple-silicon.nixosModules.apple-silicon-support
    ./hardware-configuration.nix
    ./boot.nix
    ./asahi-nvram.nix
    ./fn-power.nix
    ./ctrl-click.nix
    ./steam-muvm.nix
    ./llm
    ../../modules/system
    ../../modules/system/bluetooth.nix
    ../../modules/system/sddm.nix
  ];

  networking.hostName = "salz";
  # iwd handles the Broadcom chip's WPA3.
  networking.networkmanager.wifi.backend = "iwd";

  hardware.asahi = {
    enable = true;
    # Wi-Fi/BT firmware is per-machine and read from /boot at build time, so
    # builds need --impure. The path is explicit because the module's own
    # lookup returns null under pure evaluation.
    extractPeripheralFirmware = true;
    peripheralFirmwareDirectory = /boot/vendorfw;
  };

  # Lets the user write the trackpad's `inhibited` flag (Fn+F4 toggle).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", KERNEL=="input*", ATTR{name}=="Apple SPI Trackpad", RUN+="${pkgs.coreutils}/bin/chown ${username} %S%p/inhibited"
  '';

  # Glorious Model O hidraw access for the settings tool in ~/glorious.
  # A package, not extraRules: uaccess must be tagged before 73-seat-late.
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-glorious.rules" ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="258a", ATTRS{idProduct}=="0036|0027|0033", TAG+="uaccess"
    '')
  ];

  system.stateVersion = "25.11";
}
