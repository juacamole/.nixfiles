{ config, pkgs, ... }:
let
  sans = "Nunito";
  mono = "Maple Mono NF";
in {
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

  # Dark mode reaches apps three ways: the GTK3 theme, the dconf color-scheme
  # key (GTK4, browsers, Electron, portals) and the Qt style.
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
    gtk4.theme = config.gtk.theme;
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
