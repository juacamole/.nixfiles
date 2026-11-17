// Coffee cup: accent while the laptop is kept awake (idle-lock off).
import QtQuick
import "."

StatusItem {
    id: root
    readonly property bool awake: !IdleLock.active
    onClicked: IdleLock.toggle()

    Icon {
        anchors.centerIn: parent
        text: Theme.iCoffee
        color: root.awake ? Theme.accent : Theme.text
    }
}
