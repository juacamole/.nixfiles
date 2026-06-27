{ config, pkgs, lib, ... }:
let
  qsCfgPath = "${config.home.homeDirectory}/qstest";

  # qsctl — bar IPC dispatcher
  qsctl = pkgs.writeShellScriptBin "qsctl" ''
    exec ${pkgs.quickshell}/bin/qs -c hiromi ipc call "$@"
  '';
in
{
  home.packages = with pkgs; [
    quickshell
    swww
    eb-garamond
    ibm-plex
    nerd-fonts.jetbrains-mono
    qsctl
  ];

  # Live-editable: ~/.config/quickshell/hiromi → ~/qstest (source of truth).
  # Edits in ~/qstest reflect immediately; QS hot-reloads on file change.
  xdg.configFile."quickshell/hiromi".source =
    config.lib.file.mkOutOfStoreSymlink qsCfgPath;
}
