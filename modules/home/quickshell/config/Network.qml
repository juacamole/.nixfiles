import QtQuick
import Quickshell.Io
import "."

StatusItem {
    id: root
    property string state: "disconnected"   // "wifi:<ssid>" | "wired" | "disconnected"
    property string ssid: ""

    label: state.startsWith("wifi") ? ssid : state === "wired" ? "wired" : "offline"
    onClicked: picker.running = true

    Icon {
        anchors.centerIn: parent
        text: root.state.startsWith("wifi") ? Theme.iWifi
            : root.state === "wired" ? Theme.iWired
            : Theme.iWifiOff
        color: root.state === "disconnected" ? Theme.muted : Theme.text
    }

    Process {
        id: picker
        command: ["kitty", "--class", "net-picker", "-e", "gazelle"]
    }

    Timer {
        interval: BatterySaver.active ? 15000 : 4000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Process {
        id: poll
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        // Collected per poll and committed once on exit, so the icon never flashes "disconnected".
        property string _pendingState: "disconnected"
        property string _pendingSsid: ""
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(":")
                if (parts.length < 3 || parts[1] !== "connected") return
                if (parts[0] === "wifi") {
                    poll._pendingState = "wifi:" + parts[2]
                    poll._pendingSsid = parts[2]
                } else if (parts[0] === "ethernet" && poll._pendingState === "disconnected") {
                    poll._pendingState = "wired"
                }
            }
        }
        onStarted: { _pendingState = "disconnected"; _pendingSsid = "" }
        onExited: {
            if (root.state !== _pendingState) root.state = _pendingState
            if (root.ssid !== _pendingSsid) root.ssid = _pendingSsid
        }
    }
}
