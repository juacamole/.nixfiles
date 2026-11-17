{ pkgs, ... }:
let
  mainMod = "SUPER";
  terminal = "kitty";
  fileManager = "nautilus";
  menu = "qsctl launcher toggle";

  # Inhibit the trackpad in the kernel rather than via Hyprland's per-device
  # `enabled` keyword: that only detached the pointer, so the physical
  # clickpad button still counted as held and swallowed / stuck mouse
  # clicks. The kernel flag drops every event and releases a held button.
  # Write access comes from a udev rule in hosts/salz/configuration.nix.
  toggleTouchpad = pkgs.writeShellScript "toggle-touchpad" ''
    for d in /sys/class/input/input*; do
      [ "$(cat "$d/name")" = "Apple SPI Trackpad" ] && flag="$d/inhibited" && break
    done
    [ -n "$flag" ] || exit 1
    if [ "$(cat "$flag")" = 1 ]; then
      echo 0 > "$flag"
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Touchpad" "enabled"
    else
      echo 1 > "$flag"
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Touchpad" "disabled"
    fi
  '';

  # Runtime toggle for libinput's disable-while-typing (on by default, settings.nix).
  # A config reload resets it to the settings.nix value.
  toggleDwt = pkgs.writeShellScript "toggle-dwt" ''
    opt=input:touchpad:disable_while_typing
    if hyprctl getoption "$opt" -j | grep -q '"int": 1'; then
      hyprctl keyword "$opt" false >/dev/null
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Disable while typing" "off"
    else
      hyprctl keyword "$opt" true >/dev/null
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Disable while typing" "on"
    fi
  '';
  # Ctrl+trackpad click = right click (hosts/salz/ctrl-click.nix) on/off.
  # The daemon checks this flag on every press; the dir is user-owned.
  toggleCtrlClick = pkgs.writeShellScript "toggle-ctrl-click" ''
    flag=/var/lib/ctrl-click/on
    if [ -e "$flag" ]; then
      rm "$flag"
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Ctrl+click" "normal"
    else
      touch "$flag" || exit 1
      ${pkgs.libnotify}/bin/notify-send -t 1500 "Ctrl+click" "right click"
    fi
  '';
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

      # Fn+F4 on the Apple keyboard. hid_apple runs with fnmode=2 (F-keys
      # primary), so the chord emits the fn-row media keysym — F4's is the
      # Spotlight key, XF86Search — while bare F4 stays a plain F4.
      ", XF86Search, exec, ${toggleTouchpad}"
      # Fn+F3 (Mission Control key, KEY_SCALE = XF86LaunchA): toggle disable-while-typing.
      ", XF86LaunchA, exec, ${toggleDwt}"
      # Fn+F7 (rewind key, XF86AudioPrev): toggle Ctrl+trackpad click = right click.
      ", XF86AudioPrev, exec, ${toggleCtrlClick}"

			# Screenshot
			# satty needs --output-filename or Save (Ctrl+S) silently does nothing;
			# it won't create the dir itself, hence the mkdir.
			"${mainMod} SHIFT, S, exec, mkdir -p ~/Pictures/Screenshots && hyprshot -m region --raw | satty --filename - --output-filename ~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png --copy-command wl-copy"
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
      # Cmd+Ctrl+trackpad click: ctrl-click (hosts/salz/ctrl-click.nix) turns
      # the click into a right click, but Ctrl is still held, and mouse binds
      # need the exact modifier set, so Super alone wouldn't match.
      "${mainMod} CTRL, mouse:273, resizewindow"
    ];

    # Laptop Multimedia Keys. Each volume/brightness adjust also pokes the QS
    # OSD via qsctl so the toast pops at the same moment.
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
