// Volume / brightness toast. Fades out after 1.5s. Triggered by IPC from
// hyprland binds via `qsctl osd volume` / `qsctl osd brightness`.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import "."

Scope {
    id: root

    function showVolume(): void {
        view.label = root.muted ? "muted"
            : Math.round(root.volume * 100) + "%"
        view.value = root.muted ? 0 : root.volume
        view.kind = "vol"
        view.appear()
    }
    function showBrightness(): void {
        brightnessQuery.running = true
        view.kind = "bright"
        view.appear()
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted:  sink && sink.audio ? sink.audio.muted  : false

    PwObjectTracker { objects: [ root.sink ] }

    PanelWindow {
        id: view
        property string label: ""
        property real value: 0
        property string kind: "vol"
        property bool shown: false

        function appear(): void {
            shown = true
            hideTimer.restart()
        }

        anchors { bottom: true }
        margins { bottom: 80 }
        implicitWidth: 240
        implicitHeight: 64
        color: "transparent"
        visible: shown || card.opacity > 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Rectangle {
            id: card
            anchors.fill: parent
            color: Theme.bg
            border.color: Theme.widgetHi
            border.width: 1
            radius: Theme.widgetRadius
            opacity: view.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Column {
                anchors.centerIn: parent
                spacing: 8
                width: parent.width - 24

                Text {
                    text: view.label
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.widget
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, view.value))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.text
                        Behavior on width { NumberAnimation { duration: 120 } }
                    }
                }
            }
        }

        Timer {
            id: hideTimer
            interval: 1500
            onTriggered: view.shown = false
        }
    }

    // brightnessctl -m → "amdgpu_bl0,backlight,128,50%,255"
    Process {
        id: brightnessQuery
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(",")
                if (parts.length < 4) return
                const pctStr = parts[3].replace("%", "")
                const pct = parseInt(pctStr, 10) / 100
                view.value = pct
                view.label = Math.round(pct * 100) + "%"
            }
        }
    }
}
