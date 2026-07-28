{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.asahi-nvram ];

  # Mute the Apple Silicon boot chime by setting the system:StartupMute
  # NVRAM key (firmware reads it once at power-on, before video init).
  # asahi-nvram's write path always invalidates and re-inserts the entry,
  # so guard with a read first — NVRAM lives in NOR flash with finite
  # erase cycles, no reason to re-write the same value every boot.
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
