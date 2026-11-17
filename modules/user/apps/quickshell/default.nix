{ config, pkgs, lib, hostKind, ... }:
let
  # Bar IPC helper. SUPER+SPACE in hyprland calls `qsctl launcher toggle`.
  qsctl = pkgs.writeShellScriptBin "qsctl" ''
    exec ${pkgs.quickshell}/bin/qs -c kuan ipc call "$@"
  '';

  # Neither font is in nixpkgs. Pinned single-file downloads, installed as a
  # tiny font package so fontconfig (and therefore Qt) picks them up.
  #   Fredoka      — the shell's only text face (variable wdth/wght, OFL)
  #   tabler-icons — glyph font for every bar / popup icon (MIT); the
  #                  codepoints in Theme.qml are from this exact version
  shellFonts = pkgs.runCommand "kuan-shell-fonts" {
    fredoka = pkgs.fetchurl {
      name = "Fredoka.ttf";
      url = "https://raw.githubusercontent.com/google/fonts/cc39c4c2c304bc368c9b7c311ea2bcc6013299fe/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf";
      hash = "sha256-K6AuaLFShorvm6KOJLNkjH1Ff+byXHYfLCxT+2GnP8g=";
    };
    tabler = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.42.0/dist/fonts/tabler-icons.ttf";
      hash = "sha256-E84y9JMfzMTQd30tvC8x+lN1d7JkFmzbDWnq3Q4NKXY=";
    };
  } ''
    install -Dm444 $fredoka $out/share/fonts/truetype/Fredoka.ttf
    install -Dm444 $tabler $out/share/fonts/truetype/tabler-icons.ttf
  '';
in
{
  home.packages = with pkgs; [
    quickshell
    qsctl

    # Fonts referenced by Theme.qml
    shellFonts

    # Runtime deps used by widgets
    networkmanager        # nmcli — Network.qml polls this
    wireplumber           # wpctl — Volume.qml mutes via this
    libnotify             # notify-send for testing the notif daemon
  ];

  # Ship the QML in-store so both hosts get the same shell on rebuild.
  # No hot-reload — every QML edit needs `nix-switch`.
  xdg.configFile."quickshell/kuan".source = ./config;

  # Run the shell as a user service rather than a hyprland exec-once, so a
  # switch actually shows QML edits: the config is a store path, so the
  # running instance never sees its files change (the symlink just moves to
  # a new store path). X-Restart-Triggers changes whenever ./config does,
  # and home-manager restarts the unit on switch.
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell (kuan bar, launcher, notifications, OSD)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${./config}" ];
    };
    Service = {
      # Reap a leftover `qs -c kuan -d` from the old exec-once autostart, so
      # the first switch to this unit doesn't leave two bars stacked. Only
      # matches the daemonized form; this unit's own instance has no -d.
      ExecStartPre = "-${pkgs.procps}/bin/pkill -f -- '-c kuan -d$'";
      ExecStart = "${pkgs.quickshell}/bin/qs -c kuan";
      Restart = "on-failure";
      RestartSec = 2;
      # Widgets shell out to nmcli, wpctl, allam, idle-lock, battery-saver,
      # kitty, ...; the user manager's PATH has none of the profiles.
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
