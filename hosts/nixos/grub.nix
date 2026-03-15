{ pkgs, ... }:

let
  hollowKnightTheme = pkgs.stdenv.mkDerivation {
    pname = "hollow-knight-grub-theme";
    version = "1.0";

    src = pkgs.fetchFromGitHub {
      owner = "sergoncano";
      repo = "hollow-knight-grub-theme";
      rev = "master";
      hash = "sha256-0hn3MFC+OtfwtA//pwjnWz7Oz0Cos3YzbgUlxKszhyA="; 
    };

    installPhase = ''
      mkdir -p $out
      THEME_ROOT=$(find . -name "theme.txt" -exec dirname {} \;)
      cp -r $THEME_ROOT/* $out/
    '';
  };
in
{
  boot.loader.grub = {
    enable = true;
    theme = hollowKnightTheme;
    gfxmodeEfi = "1920x1080";
  };
}
