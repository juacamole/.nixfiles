// Volume / brightness toast, bottom center. Rises softly into view, lingers,
// sinks away. Triggered by IPC from hyprland binds via `qsctl osd ...`.
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
        margins { bottom: 72 }
        implicitWidth: 280
        implicitHeight: 56
        color: "transparent"
        // Stay mapped while the exit fade plays out.
        visible: shown || card.opacity > 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Slab {
            id: card
            // Leave room inside the window for the hard shadow.
            width: parent.width - shadow
            height: parent.height - shadow
            shadow: Theme.cardShadow
            opacity: view.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeInOut } }
            transform: Translate {
                y: view.shown ? 0 : 14
                Behavior on y { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }
            }

            Icon {
                id: icon
                font.pixelSize: 22
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: view.kind === "bright" ? Theme.iSun
                    : root.muted ? Theme.iVolumeOff : Theme.iVolume
                color: view.kind === "vol" && root.muted ? Theme.red : Theme.text
            }

            Text {
                id: pct
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: view.label
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                anchors.left: icon.right
                anchors.leftMargin: 12
                anchors.right: pct.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 7
                radius: 4
                color: Theme.track
                border.color: Theme.ink
                border.width: 1

                Rectangle {
                    x: 1; y: 1
                    width: (parent.width - 2) * Math.max(0, Math.min(1, view.value))
                    height: parent.height - 2
                    radius: 3
                    color: Theme.yellow
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Theme.easeOut } }
                }
            }
        }

        Timer {
            id: hideTimer
            interval: 1600
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
