// Entry point: one Bar per screen, the overlays, and the IPC targets behind `qsctl`.
import QtQuick
import Quickshell
import Quickshell.Io
import "."

ShellRoot {
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

    IpcHandler {
        target: "battery-saver"
        function toggle():  void { BatterySaver.toggle() }
        function refresh(): void { BatterySaver.refresh() }
    }
}
