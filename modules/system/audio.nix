{ pkgs, ... }: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  environment.systemPackages = [ pkgs.alsa-utils ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
