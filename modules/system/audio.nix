{ pkgs, ... }: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  environment.systemPackages = [ pkgs.alsa-utils ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # XWayland apps (Unity Hub) ring the X11 bell every few seconds.
    extraConfig.pipewire."99-no-x11-bell" = {
      "context.properties"."module.x11.bell" = false;
    };
  };
}
