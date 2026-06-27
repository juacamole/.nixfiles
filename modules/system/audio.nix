{ pkgs, ... }: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  environment.systemPackages = [ pkgs.alsa-utils ];

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

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
