{ pkgs, ... }:
let
  themeName = "pixel-hollowknight";

  # Sparse checkout: the whole repo is ~570 MB of themes.
  qylock = pkgs.fetchgit {
    url = "https://github.com/Darkkal44/qylock";
    rev = "c2933f27b655a999911e6699e1b2c67e59cbd428";
    sparseCheckout = [ "themes/${themeName}" ];
    hash = "sha256-6NeaoYnJrjp37fBt/cWqtpgoUHBucIe+qPlEZLIrrNk=";
  };

  theme = pkgs.runCommand "sddm-theme-${themeName}" { } ''
    mkdir -p $out/share/sddm/themes
    cp -r ${qylock}/themes/${themeName} $out/share/sddm/themes/${themeName}
  '';
in {
  services.displayManager = {
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = themeName;
      extraPackages = with pkgs.qt6; [
        qt5compat
        qtmultimedia
        qtsvg
      ];
    };
  };

  environment.systemPackages = [ theme ];
}
