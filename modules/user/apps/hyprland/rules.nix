{ ... }: {
  wayland.windowManager.hyprland.settings = {

    workspace = [
      "w[tv1-10], gapsout:5, gapsin:3"
    ];

    # Steam UI is CEF: the webhelper crashes intermittently under FEX (futex2
    # quirks) and Steam recreates its main window. Without these rules the
    # new window lands on whichever workspace is focused — which is what the
    # "Steam moves between workspaces" symptom was.
    # Hyprland 0.54 syntax: comma-separated `match:<prop> <regex>` filters
    # and `<effect> <value>` entries, freely ordered.
    windowrule = [
      "workspace 9 silent, match:class ^steam$, match:title ^Steam$"
      "float true, match:class ^steam$, match:title ^(Friends List|Steam Settings|Add a Non-Steam Game.*)$"
      "no_initial_focus true, match:class ^steam$, match:title ^$"
    ];
  };
}
