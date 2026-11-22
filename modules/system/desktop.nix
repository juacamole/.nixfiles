{ pkgs, ... }: {
  programs.hyprland.enable = true;
  # Still needed for the xkb settings.
  services.xserver.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Backend for home-manager's dconf.settings (dark mode key).
  programs.dconf.enable = true;
  # Without GVfs the GTK4 file chooser cannot list folders.
  services.gvfs.enable = true;
  services.upower.enable = true;
  services.tailscale.enable = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
}
