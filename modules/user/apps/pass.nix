{ pkgs, config, ... }: {

  # pass (password-store) + tessen as the Wayland picker. tessen reads its
  # backends from ~/.config/tessen/config; fuzzel is the dmenu it drives and
  # wtype does the autotype. Store lives in the XDG data dir, not ~/.password-store.
  programs.password-store = {
    enable = true;
    package = pkgs.pass-wayland.withExtensions (exts: [ exts.pass-otp ]);
    settings.PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
  };

  programs.gpg.enable = true;

  # No GNOME session here, so use the Qt pinentry: it pops a standalone
  # window instead of falling back to curses when gcr isn't on the bus.
  services.gpg-agent = {
    enable = true;
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
