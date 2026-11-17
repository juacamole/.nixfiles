{ pkgs, ... }:
let
  # "pixel-hollowknight" from Darkkal44/qylock. Sparse checkout of just this
  # theme: the full repo is ~570 MB of themes, this one is ~40 MB (bg.mp4).
  themeName = "pixel-hollowknight";
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
      # Wayland greeter (weston as the greeter compositor); no X server needed.
      wayland.enable = true;
      theme = themeName;
      extraPackages = with pkgs.qt6; [
        qt5compat    # Qt5Compat.GraphicalEffects
        qtmultimedia # MediaPlayer/VideoOutput for the bg.mp4 background
        qtsvg
      ];
    };
  };

  environment.systemPackages = [ theme ];
}
