// Polls `nmcli` for the active connection. Click opens `gazelle` (the user's
// TUI of choice — set up in apps/gazelle.nix) in a kitty popup.
import QtQuick
import Quickshell.Io
import "."

Item {
    id: root
    property string state: "disconnected"   // "wifi:<ssid>" | "wired" | "disconnected"
    property string ssid: ""

    implicitWidth: row.implicitWidth + Theme.widgetPad * 2
    implicitHeight: Theme.barHeight - 8

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: hover.containsMouse ? Theme.widgetHi : Theme.widget
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.state.startsWith("wifi") ? ""   // nf wifi
                : root.state === "wired"        ? "󰈀"   // nf ethernet
                                                : "󰖪"   // nf wifi-off
            color: root.state === "disconnected" ? Theme.faint : Theme.dim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSize
            renderType: Text.NativeRendering
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.state.startsWith("wifi") ? root.ssid : ""
            visible: text.length > 0
            color: Theme.text
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSize
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            // Keep SSIDs from making the bar wobble.
            width: Math.min(implicitWidth, 120)
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: picker.running = true
    }

    Process {
        id: picker
        command: ["kitty", "--class", "net-picker", "-e", "gazelle"]
    }

    // Refresh every 4s. nmcli is cheap and avoids wiring up the NetworkManager
    // DBus interface from QML (which Quickshell doesn't expose first-class).
    // Backs off to 15s in battery-saver mode — nmcli forks aren't free.
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
        // Accumulate per-poll into pending props, commit once on exit so QML
        // sees a single state transition (and skips the assignment entirely if
        // it matches the last poll). Resetting root.state in onStarted made
        // every 4s tick flash the icon to "disconnected" before reconnecting.
        property string _pendingState: "disconnected"
        property string _pendingSsid: ""
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(":")
                if (parts.length < 3 || parts[1] !== "connected") return
                if (parts[0] === "wifi") {
                    poll._pendingState = "wifi:" + parts[2]
                    poll._pendingSsid = parts[2]
                } else if (parts[0] === "ethernet") {
                    poll._pendingState = "wired"
                }
            }
        }
        onStarted: { _pendingState = "disconnected"; _pendingSsid = "" }
        onExited: {
            root.state = _pendingState
            root.ssid = _pendingSsid
        }
    }
}
