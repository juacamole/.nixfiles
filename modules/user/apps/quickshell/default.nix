{ config, pkgs, lib, hostKind, ... }:
let
  # Bar IPC helper. SUPER+SPACE in hyprland calls `qsctl launcher toggle`.
  qsctl = pkgs.writeShellScriptBin "qsctl" ''
    exec ${pkgs.quickshell}/bin/qs -c kuan ipc call "$@"
  '';
in
{
  home.packages = with pkgs; [
    quickshell
    qsctl

    # Fonts referenced by Theme.qml
    inter
    nerd-fonts.jetbrains-mono

    # Runtime deps used by widgets
    networkmanager        # nmcli — Network.qml polls this
    wireplumber           # wpctl — Volume.qml mutes via this
    libnotify             # notify-send for testing the notif daemon
  ];

  # Ship the QML in-store so both hosts get the same shell on rebuild.
  # No hot-reload — every QML edit needs `nix-switch`.
  xdg.configFile."quickshell/kuan".source = ./config;
}
