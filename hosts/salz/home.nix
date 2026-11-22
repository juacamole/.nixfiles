{ ... }: {
  imports = [
    ../../modules/home
    ../../modules/home/pi
    ../../modules/home/battery-saver.nix
    ../../modules/home/orbitty
  ];

  services.battery-warn.device = "macsmc-battery";

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "eDP-1, preferred, 0x0, 2"
      ", preferred, auto, 1"
    ];
    # Would clash with Steam's own -forcedesktopscaling under muvm.
    xwayland.force_zero_scaling = false;
  };
}
