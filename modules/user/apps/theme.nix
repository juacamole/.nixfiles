{ pkgs, ... }:
# Desktop-wide look outside the shell: soft fonts + dark mode everywhere.
#
# Fonts: rounded faces to match the "ink & cream" bar (which uses Fredoka).
#   Nunito          — UI / prose (GTK, Qt, browsers' sans-serif default)
#   Maple Mono NF   — monospace with rounded forms + nerd-font glyphs
#                     (kitty, nvim, anything asking fontconfig for monospace)
# Fredoka stays shell-only: lovely at bar sizes, too playful for body text.
#
# Dark mode reaches apps three ways, so all three are set:
#   * GTK3     — the adw-gtk3-dark theme (GTK3 has no colour-scheme switch)
#   * GTK4 / libadwaita, Firefox/Zen, Electron, portals — the
#     org.gnome.desktop.interface color-scheme key, which
#     xdg-desktop-portal-gtk re-exports as the Settings portal's
#     color-scheme. Needs programs.dconf on the system (desktop.nix).
#   * Qt       — adwaita-dark style via the adwaita platform theme
let
  sans = "Nunito";
  mono = "Maple Mono NF";
in
{
  home.packages = with pkgs; [
    nunito
    maple-mono.NF
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ sans ];
      monospace = [ mono ];
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    font = {
      name = sans;
      size = 11;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
    font-name = "${sans} 11";
    document-font-name = "${sans} 11";
    monospace-font-name = "${mono} 11";
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
}
