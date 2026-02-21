{ pkgs, ... }: 
let
  mainMod = "SUPER";
  terminal = "kitty";
  fileManager = "nautilus";
  menu = "rofi -show run";
in {
  wayland.windowManager.hyprland.settings = {
    bind = [
      "${mainMod} SHIFT, B, exec, ~/.config/hypr/scripts/waybar-launch.sh"
      "${mainMod}, RETURN, exec, ${terminal}"
      "${mainMod}, Q, killactive,"
      "${mainMod} SHIFT, M, exec, hyprlock"
      "${mainMod}, E, exec, ${fileManager}"
      "${mainMod}, V, togglefloating,"
      "${mainMod}, SPACE, exec, ${menu}"
      "${mainMod}, F, fullscreen,"
      "${mainMod}, Z, exec, zen-beta"
      "${mainMod}, P, pseudo," 
      "${mainMod}, I, togglesplit," 
      "${mainMod}, Tab, changegroupactive, f"

			# Screenshot
			"${mainMod} SHIFT, S, exec, hyprshot -m region --raw | satty --filename -"
      # Move focus
      "${mainMod}, H, movefocus, l"
      "${mainMod}, L, movefocus, r"
      "${mainMod}, K, movefocus, u"
      "${mainMod}, J, movefocus, d"

      # Move window
      "${mainMod} SHIFT, H, movewindow, l"
      "${mainMod} SHIFT, L, movewindow, r"
      "${mainMod} SHIFT, K, movewindow, u"
      "${mainMod} SHIFT, J, movewindow, d"

      # Workspaces scroll
      "${mainMod}, mouse_down, workspace, e+1"
      "${mainMod}, mouse_up, workspace, e-1"
    ] ++ (
      # Automatically generate workspace binds (1-10)
      builtins.concatLists (builtins.genList (i:
        let 
          ws = i + 1;
          wsStr = toString ws;
          key = if ws == 10 then "0" else wsStr;
        in [
          "${mainMod}, ${key}, workspace, ${wsStr}"
          "${mainMod} SHIFT, ${key}, movetoworkspace, ${wsStr}"
        ]
      ) 10)
    );

    # Mouse Binds
    bindm = [
      "${mainMod}, mouse:272, movewindow"
      "${mainMod}, mouse:273, resizewindow"
    ];

    # Laptop Multimedia Keys
    bindel = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ];
  };
}
