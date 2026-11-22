{ pkgs, ... }:
let
  mainMod = "SUPER";
  terminal = "kitty";
  fileManager = "nautilus";
  menu = "qsctl launcher toggle";
  notify = "${pkgs.libnotify}/bin/notify-send -t 1500";

  # Kernel-level inhibit. Hyprland's per-device `enabled` leaves the physical
  # click held, which then swallows mouse clicks.
  toggleTouchpad = pkgs.writeShellScript "toggle-touchpad" ''
    for d in /sys/class/input/input*; do
      [ "$(cat "$d/name")" = "Apple SPI Trackpad" ] && flag="$d/inhibited" && break
    done
    [ -n "$flag" ] || exit 1
    if [ "$(cat "$flag")" = 1 ]; then
      echo 0 > "$flag"
      ${notify} "Touchpad" "enabled"
    else
      echo 1 > "$flag"
      ${notify} "Touchpad" "disabled"
    fi
  '';

  # Lasts until the next config reload.
  toggleDwt = pkgs.writeShellScript "toggle-dwt" ''
    opt=input:touchpad:disable_while_typing
    if hyprctl getoption "$opt" -j | grep -q '"int": 1'; then
      hyprctl keyword "$opt" false >/dev/null
      ${notify} "Disable while typing" "off"
    else
      hyprctl keyword "$opt" true >/dev/null
      ${notify} "Disable while typing" "on"
    fi
  '';

  # Flag read by the ctrl-click daemon (hosts/salz/ctrl-click.nix).
  toggleCtrlClick = pkgs.writeShellScript "toggle-ctrl-click" ''
    flag=/var/lib/ctrl-click/on
    if [ -e "$flag" ]; then
      rm "$flag"
      ${notify} "Ctrl+click" "normal"
    else
      touch "$flag" || exit 1
      ${notify} "Ctrl+click" "right click"
    fi
  '';

  # Region straight to the clipboard; only the 5 newest shots are kept.
  screenshot = pkgs.writeShellScript "screenshot" ''
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
    ${pkgs.hyprshot}/bin/hyprshot -m region --raw > "$file"
    [ -s "$file" ] || { rm -f "$file"; exit 0; }
    ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$file"
    ls -1t "$dir"/????-??-??_??-??-??.png | tail -n +6 | xargs -r rm --
  '';

  workspaceBinds = builtins.concatLists (builtins.genList (i:
    let
      ws = toString (i + 1);
      key = if i == 9 then "0" else ws;
    in [
      "${mainMod}, ${key}, workspace, ${ws}"
      "${mainMod} SHIFT, ${key}, movetoworkspace, ${ws}"
    ]
  ) 10);
in {
  wayland.windowManager.hyprland.settings = {
    bind = [
      "${mainMod}, RETURN, exec, ${terminal}"
      "${mainMod}, Q, killactive,"
      "${mainMod} SHIFT, M, exec, hyprlock"
      "${mainMod}, E, exec, ${fileManager}"
      "${mainMod} SHIFT, U, togglefloating,"
      "${mainMod}, SPACE, exec, ${menu}"
      "${mainMod} ALT, C, exec, qsctl clock toggle"
      "${mainMod}, F, fullscreen,"
      "${mainMod}, Z, exec, zen-beta"
      "${mainMod}, P, pseudo,"
      "${mainMod}, I, layoutmsg, togglesplit"
      "${mainMod}, Tab, changegroupactive, f"

      # Apple Fn row: Fn+F4, Fn+F3, Fn+F7.
      ", XF86Search, exec, ${toggleTouchpad}"
      ", XF86LaunchA, exec, ${toggleDwt}"
      ", XF86AudioPrev, exec, ${toggleCtrlClick}"

      "${mainMod} SHIFT, S, exec, ${screenshot}"

      "${mainMod}, H, movefocus, l"
      "${mainMod}, L, movefocus, r"
      "${mainMod}, K, movefocus, u"
      "${mainMod}, J, movefocus, d"

      "${mainMod} SHIFT, H, movewindow, l"
      "${mainMod} SHIFT, L, movewindow, r"
      "${mainMod} SHIFT, K, movewindow, u"
      "${mainMod} SHIFT, J, movewindow, d"

      "${mainMod}, mouse_down, workspace, e+1"
      "${mainMod}, mouse_up, workspace, e-1"
    ] ++ workspaceBinds;

    bindm = [
      "${mainMod}, mouse:272, movewindow"
      "${mainMod}, mouse:273, resizewindow"
      # A ctrl-click right click still has Ctrl held.
      "${mainMod} CTRL, mouse:273, resizewindow"
    ];

    # Each adjust also pops the quickshell OSD.
    bindel = [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && qsctl osd volume"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && qsctl osd volume"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qsctl osd volume"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86MonBrightnessUp, exec, brightnessctl set 5%+ && qsctl osd brightness"
      ", XF86MonBrightnessDown, exec, brightnessctl set 5%- && qsctl osd brightness"
    ];
  };
}
