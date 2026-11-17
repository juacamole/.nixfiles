{ config, pkgs, ... }:
let
  qsctl = pkgs.writeShellScriptBin "qsctl" ''
    exec ${pkgs.quickshell}/bin/qs -c kuan ipc call "$@"
  '';

  # Neither font is in nixpkgs. The icon codepoints in Theme.qml belong to
  # this exact tabler version.
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
in {
  home.packages = with pkgs; [
    quickshell
    qsctl
    shellFonts
    # Called by the widgets: nmcli, wpctl, notify-send.
    networkmanager
    wireplumber
    libnotify
  ];

  # The QML ships in the store, so there is no hot reload: edit, then nix-switch.
  xdg.configFile."quickshell/kuan".source = ./config;

  # A user service so that a switch restarts the shell when ./config changes.
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell (kuan bar, launcher, notifications, OSD)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${./config}" ];
    };
    Service = {
      # Kills a bar left over from the old exec-once autostart.
      ExecStartPre = "-${pkgs.procps}/bin/pkill -f -- '-c kuan -d$'";
      ExecStart = "${pkgs.quickshell}/bin/qs -c kuan";
      Restart = "on-failure";
      RestartSec = 2;
      # Widgets shell out to tools in the profiles, which the user manager's
      # PATH does not include.
      Environment = [
        "PATH=${config.home.profileDirectory}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
