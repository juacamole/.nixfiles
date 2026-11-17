{ ... }: {
  wayland.windowManager.hyprland.settings = {
    workspace = [
      "w[tv1-10], gapsout:5, gapsin:3"
    ];

    # Steam recreates its main window whenever the webhelper crashes; pin it
    # so it does not jump to the focused workspace.
    windowrule = [
      "workspace 9 silent, match:class ^steam$, match:title ^Steam$"
      "float true, match:class ^steam$, match:title ^(Friends List|Steam Settings|Add a Non-Steam Game.*)$"
      "no_initial_focus true, match:class ^steam$, match:title ^$"
    ];
  };
}
