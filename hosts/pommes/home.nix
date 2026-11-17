{ pkgs, lib, ... }: {
  imports = [
    ../../modules/home
    ../../modules/home/orbitty
  ];

  home.packages = with pkgs; [
    steam-run
    scarab
    discord-ptb
    nbfc-linux
  ];

  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  programs.zsh.shellAliases.battery = "cat /sys/class/power_supply/BAT1/capacity";

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1, 1920x1080@60, 0x0, 1"
      ", preferred, auto, 1"
    ];
    # Written by nwg-displays, outside the flake.
    source = [ "~/.config/hypr/monitors.conf" ];

    env = [
      "LIBVA_DRIVER_NAME, nvidia"
      "GBM_BACKEND, nvidia-drm"
      "__GLX_VENDOR_LIBRARY_NAME, nvidia"
    ];
    exec-once = lib.mkAfter [ "~/bash/tanatos/tanatos.sh" ];
    xwayland.force_zero_scaling = true;
  };
}
