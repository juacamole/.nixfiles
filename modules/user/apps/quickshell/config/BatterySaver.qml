// Global singleton for battery-saver mode state.
//
// Source of truth is the file at $XDG_STATE_HOME/quickshell/battery-saver,
// owned exclusively by the `battery-saver` script. This QML never writes it
// directly — every state change goes through `battery-saver toggle`, and we
// re-read the file afterwards. A slow 30s poll picks up out-of-band changes
// (session-start `apply`, notification-action clicks, manual CLI use).
pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool active: false

    function toggle(): void { toggleProc.running = true }
    function refresh(): void { statusProc.running = true }

    Process {
        id: statusProc
        command: ["battery-saver", "status"]
        stdout: SplitParser {
            onRead: line => {
                const next = line.trim() === "on"
                // Guard against spurious re-assigns — flicker discipline for
                // consumers that bind implicit widths / colours to `active`.
                if (root.active !== next) root.active = next
            }
        }
    }

    Process {
        id: toggleProc
        command: ["battery-saver", "toggle"]
        onExited: statusProc.running = true
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }
}
