{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.asahi-nvram ];

  # Reads before writing: NVRAM is NOR flash, and every write costs an erase cycle.
  systemd.services.asahi-mute-boot-chime = {
    description = "Mute Apple Silicon boot chime via NVRAM";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      out=$(${pkgs.asahi-nvram}/bin/asahi-nvram read system:StartupMute 2>/dev/null || true)
      case "$out" in
        *=%01) ;;
        *) ${pkgs.asahi-nvram}/bin/asahi-nvram write system:StartupMute=%01 ;;
      esac
    '';
  };
}
