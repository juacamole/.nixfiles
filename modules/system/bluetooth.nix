{ pkgs, ... }: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings.General = {
      # Battery levels of headphones and mice, read by UPower.
      Experimental = true;
      ControllerMode = "dual";
      # Lets AirPods reconnect on their own after they drop the idle link.
      FastConnectable = true;
    };
  };

  # blueman-manager is a plain window, so it works without a system tray.
  services.blueman.enable = true;
  # Blueman's device icons need a full icon theme; hicolor alone has none.
  environment.systemPackages = [ pkgs.adwaita-icon-theme ];
}
