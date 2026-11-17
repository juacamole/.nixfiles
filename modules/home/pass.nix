{ pkgs, config, ... }: {
  # pass, with tessen as the picker: fuzzel is its menu, wtype does the autotype.
  programs.password-store = {
    enable = true;
    package = pkgs.pass-wayland.withExtensions (exts: [ exts.pass-otp ]);
    settings.PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
  };

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    # Opens its own window; the default falls back to curses without GNOME.
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
  };

  programs.fuzzel.enable = true;
  home.packages = with pkgs; [
    tessen
    wtype
  ];

  xdg.configFile."tessen/config".text = ''
    pass_backend="pass"
    dmenu_backend="fuzzel"
    action="default"
  '';
}
