import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Io
import "."

StatusItem {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    label: muted ? "muted" : Math.round(volume * 100) + "%"
    onClicked: muteToggle.running = true
    onWheel: event => {
        const step = event.angleDelta.y > 0 ? "5%+" : "5%-"
        wpVol.command = ["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", step]
        wpVol.running = true
    }

    PwObjectTracker { objects: [ root.sink ] }

    Icon {
        anchors.centerIn: parent
        text: root.muted ? Theme.iVolumeOff
            : root.volume > 0.5 ? Theme.iVolume
            : Theme.iVolume1
        color: root.muted ? Theme.red
             : root.volume <= 0.005 ? Theme.muted
             : Theme.text
    }

    Process { id: muteToggle; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }
    Process { id: wpVol }
}
