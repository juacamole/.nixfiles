// Small leaf-icon widget that appears left of Battery when saver mode is on.
// Icon-only, fixed implicit width — its appear/disappear does not reflow the
// bar center (Clock is anchored to bar centre, not laid out by the RowLayout).
import QtQuick
import "."

Item {
    id: root
    visible: BatterySaver.active

    implicitWidth: visible ? label.implicitWidth + Theme.widgetPad * 2 : 0
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
        text: ""  // nf-fa-leaf (U+F06C)
        color: Theme.warn
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSize
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: BatterySaver.toggle()
    }
}
