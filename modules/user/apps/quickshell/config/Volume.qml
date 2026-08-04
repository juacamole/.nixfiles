// Default sink volume (Pipewire). Click toggles mute. Scrolling adjusts.
import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Io
import "."

Item {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    implicitWidth: row.implicitWidth + Theme.widgetPad * 2
    implicitHeight: Theme.barHeight - 8

    PwObjectTracker { objects: [ root.sink ] }

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
            text: root.muted ? "󰖁" // nf-md-volume-off (U+F0581)
                 : root.volume > 0.66 ? "󰕾" // nf-md-volume-high (U+F057E)
                 : root.volume > 0.33 ? "󰖀" // nf-md-volume-medium (U+F0580)
                 : "󰕿" // nf-md-volume-low (U+F057F)
            color: root.muted ? Theme.faint : Theme.dim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSize
            renderType: Text.NativeRendering
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            // Right-pad to 4 chars ("100%", "  5%") so the widget width is
            // constant — otherwise scrolling volume reflows the RowLayout and
            // shifts Network/Battery on every step.
            text: {
                const s = Math.round(root.volume * 100) + "%"
                return s.padStart(4, " ")
            }
            color: root.muted ? Theme.faint : Theme.text
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSize
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: muteToggle.running = true
        onWheel: wheelEvent => {
            const step = wheelEvent.angleDelta.y > 0 ? "5%+" : "5%-"
            wpVol.command = ["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", step]
            wpVol.running = true
        }
    }

    Process { id: muteToggle; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }
    Process { id: wpVol }
}
