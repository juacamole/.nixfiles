// The `idle-lock` script owns the state; this only calls it and re-reads `status`.
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
        command: ["idle-lock", "status"]
        stdout: SplitParser {
            onRead: line => {
                const next = line.trim() === "on"
                if (root.active !== next) root.active = next
            }
        }
    }

    Process {
        id: toggleProc
        command: ["idle-lock", "toggle"]
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
