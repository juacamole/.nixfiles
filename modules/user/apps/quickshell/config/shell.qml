// Entry point. Instantiates one Bar per screen plus the global overlays
// (launcher, notification center, OSD) and registers the IPC handlers that
// hyprland binds drive via `qsctl`.
import QtQuick
import Quickshell
import Quickshell.Io
import "."

ShellRoot {
    // One bar per connected screen. Variants sets `modelData` on each Bar.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Launcher      { id: launcher }
    Notifications { id: notifications }
    OSD           { id: osd }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
        function open():   void { launcher.open() }
        function close():  void { launcher.close() }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { notifications.toggle() }
    }

    IpcHandler {
        target: "osd"
        function volume(): void { osd.showVolume() }
        function brightness(): void { osd.showBrightness() }
    }

    // Lets external triggers (session-start apply, low-battery notification
    // action, manual `qsctl battery-saver ...`) resync the singleton after
    // out-of-band state changes.
    IpcHandler {
        target: "battery-saver"
        function toggle():  void { BatterySaver.toggle() }
        function refresh(): void { BatterySaver.refresh() }
    }
}
