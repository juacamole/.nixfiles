{ config, pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./asahi-nvram.nix
    ./fn-power.nix
    ./ctrl-click.nix
    ../../modules/system/desktop.nix
    ../../modules/system/audio.nix
    ../../modules/system/bluetooth.nix
    ../../modules/system/steam-muvm.nix
    ../../modules/system/llm.nix
    ../../modules/system/sddm.nix
  ];

  # Asahi kernel / firmware / hardware support is provided by the
  # apple-silicon-support nixosModule (wired in flake.nix). It applies its
  # own overlay and sets boot.kernelPackages to the Asahi kernel — do NOT
  # override boot.kernelPackages anywhere for this host.
  hardware.asahi.enable = true;

  # Peripheral firmware (Wi-Fi/BT calibration) is loaded from
  # /boot/vendorfw/firmware.cpio at build time. This is per-machine data
  # placed there by the Asahi installer and is NEVER committed to this public
  # repo. Builds therefore require `--impure`.
  #
  # The path is set explicitly instead of relying on the module's
  # `lib.findFirst` default, which uses `builtins.pathExists` and silently
  # returns `null` under pure evaluation, tripping a confusing assertion
  # ("firmware location appears incorrect") even when the file is present.
  hardware.asahi.extractPeripheralFirmware = true;
  hardware.asahi.peripheralFirmwareDirectory = /boot/vendorfw;

  # Basic System Settings
  networking.hostName = "salz";
  networking.networkmanager.enable = true;
  # iwd backend: recommended on Macs (Broadcom WPA3 support).
  networking.networkmanager.wifi.backend = "iwd";

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "ch";
    variant = "";
  };
  console.keyMap = "sg";

  # Let the user write the trackpad's kernel `inhibited` flag, used by the
  # Fn+F4 toggle (modules/user/apps/hyprland/binds.nix). Inhibiting at the
  # kernel drops the physical click too and releases a held button, which
  # Hyprland's per-device `enabled = false` does not.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", KERNEL=="input*", ATTR{name}=="Apple SPI Trackpad", RUN+="${pkgs.coreutils}/bin/chown ${username} %S%p/inhibited"
  '';

  # Glorious Model O: let the logged-in user open its hidraw node, for the
  # settings tool in ~/glorious. Shipped as a package rather than extraRules
  # because uaccess is applied in 73-seat-late, and extraRules (99-local)
  # would come too late.
  services.udev.packages = [
    (pkgs.writeTextDir "lib/udev/rules.d/70-glorious.rules" ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="258a", ATTRS{idProduct}=="0036|0027|0033", TAG+="uaccess"
    '')
  ];

  # The power button is the Touch ID key next to F12, easy to hit by
  # accident. Have logind ignore it; Fn+Power shuts down instead
  # (fn-power.nix), and holding it still forces a firmware power-off.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "ignore";
  };

  # Shell Configuration
  programs.zsh.enable = true;

  # Login Manager: SDDM, see modules/system/sddm.nix

  # User Definition
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "video" "render" "docker" ];
    shell = pkgs.zsh;
  };

  # Nix Maintenance
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  virtualisation.docker.enable = true;

  # Allow running unpatched dynamic binaries (npm packages, etc.)
  programs.nix-ld.enable = true;

  system.stateVersion = "25.11";
}
