{ pkgs, ... }: {
  # xserver still needed for xkb settings and nvidia driver loading
  services.xserver.enable = true;
  services.tailscale.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  programs.hyprland.enable = true;

  # dconf backend for home-manager's dconf.settings (apps/theme.nix): the
  # dark color-scheme key that GTK4, browsers and the portal read lives there.
  programs.dconf.enable = true;

  # UPower DBus service — feeds the QS Battery widget.
  services.upower.enable = true;

  # GIO/GVfs backends. Without them the GTK4 file chooser (e.g. satty's
  # Save As) errors with "The folder contents could not be displayed".
  services.gvfs.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
