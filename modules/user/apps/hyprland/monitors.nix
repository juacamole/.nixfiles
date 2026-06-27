{ hostKind, ... }: {
  wayland.windowManager.hyprland.settings = {
    monitor =
      if hostKind == "mac" then [
        # TODO(salz): confirm connector name, native res + scale from the
        # running display. Apple internal panel is hi-DPI; placeholder below.
        "eDP-1, preferred, 0x0, 2"
        ", preferred, auto, 1"
      ] else [
        "eDP-1, 1920x1080@60, 0x0, 1"
        ", preferred, auto, 1"
      ];
  };
}
