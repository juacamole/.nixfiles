// Lock-icon toggle for idle-lock, sits just right of Workspaces. Always
// visible (unlike BatterySaverIndicator). State is conveyed the house way —
// brightness + weight, not colour: bright/bold lock = idle-lock ON, faint
// unlock = OFF. Click toggles.
import QtQuick
import "."

Item {
    id: root
    implicitWidth: label.implicitWidth + Theme.widgetPad * 2
    implicitHeight: Theme.barHeight - 8

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: mouse.containsMouse ? Theme.widgetHi : Theme.widget
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        // nf-md-lock (U+F033E) when on, nf-md-lock-open (U+F033F) when off.
        text: IdleLock.active ? "󰌾" : "󰌿"
        color: IdleLock.active ? Theme.text : Theme.faint
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSize
        font.bold: IdleLock.active
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: IdleLock.toggle()
    }
}
