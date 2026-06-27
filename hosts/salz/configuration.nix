{ config, pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules/system/desktop.nix
    ../../modules/system/audio.nix
  ];

  # Asahi kernel / firmware / hardware support is provided by the
  # apple-silicon-support nixosModule (wired in flake.nix). It applies its
  # own overlay and sets boot.kernelPackages to the Asahi kernel — do NOT
  # override boot.kernelPackages anywhere for this host.
  hardware.asahi.enable = true;

  # Peripheral firmware (Wi-Fi/BT calibration) is read from /boot/asahi at
  # build time. This is per-machine data extracted from macOS and is NEVER
  # committed to this public repo. Builds therefore require `--impure`.
  #
  # The path is set explicitly here instead of relying on the module's
  # `lib.findFirst` default, which uses `builtins.pathExists` and silently
  # returns `null` under pure evaluation, tripping a confusing assertion
  # ("firmware location appears incorrect") even when /boot/asahi is present.
  hardware.asahi.extractPeripheralFirmware = true;
  hardware.asahi.peripheralFirmwareDirectory = /boot/asahi;

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

  # Shell Configuration
  programs.zsh.enable = true;

  # Login Manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
        user = username;
      };
    };
  };
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

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
