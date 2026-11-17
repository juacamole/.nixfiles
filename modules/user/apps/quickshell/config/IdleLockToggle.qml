// Coffee cup = idle inhibitor. Dim while the laptop may idle-lock / sleep
// (idle-lock on), yellow while it's being kept awake (idle-lock off — see
// hypridle.nix: that also holds the lid-switch inhibitor). Click toggles via
// the IdleLock singleton.
import QtQuick
import "."

StatusItem {
    id: root
    readonly property bool awake: !IdleLock.active
    onClicked: IdleLock.toggle()

    Icon {
        anchors.centerIn: parent
        text: Theme.iCoffee
        color: root.awake ? Theme.yellow : Theme.text
    }
}
