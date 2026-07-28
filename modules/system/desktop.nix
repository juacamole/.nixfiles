{ pkgs, ... }: {
  # xserver still needed for xkb settings and nvidia driver loading
  services.xserver.enable = true;
  services.tailscale.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  programs.hyprland.enable = true;

  # UPower DBus service — feeds the QS Battery widget.
  services.upower.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
