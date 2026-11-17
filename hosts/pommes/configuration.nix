{ config, pkgs, username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules/system
  ];

  networking.hostName = "pommes";

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # The internal HDA card on this Acer comes up muted.
  systemd.services.unmute-headphone = {
    description = "Unmute ALSA Headphone switch on internal HDA";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" "pipewire.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c 0 sset Master unmute 80%
      ${pkgs.alsa-utils}/bin/amixer -c 0 sset Headphone unmute 80%
    '';
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
      user = username;
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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # PrismLauncher's bundled LWJGL GLFW is broken here.
  environment.sessionVariables = {
    PRISMLAUNCHER_USE_SYSTEM_GLFW = "1";
    PRISMLAUNCHER_USE_SYSTEM_OPENAL = "1";
  };

  nixpkgs.config.permittedInsecurePackages = [ "openssl-1.1.1w" ];

  system.stateVersion = "25.11";
}
