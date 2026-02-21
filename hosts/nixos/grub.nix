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
      # Find the directory containing theme.txt, wherever it is
      THEME_ROOT=$(find . -name "theme.txt" -exec dirname {} \;)
      
      # Copy everything from that directory into the output
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
