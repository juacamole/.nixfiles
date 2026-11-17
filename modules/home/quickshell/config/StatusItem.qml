// A glyph in the status pill. Hovering unfolds `label` beside it.
import QtQuick
import "."

Item {
    id: root
    property string label: ""
    property int glyphWidth: Theme.iconSize
    readonly property bool hovered: mouse.containsMouse

    signal clicked()
    signal wheel(var event)

    default property alias glyph: glyphSlot.data

    implicitWidth: glyphWidth + (hovered && label.length > 0 ? 5 + value.implicitWidth : 0)
    implicitHeight: Theme.pillHeight
    Behavior on implicitWidth { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }
    clip: true

    Item {
        id: glyphSlot
        width: root.glyphWidth
        height: parent.height
    }

    Text {
        id: value
        x: root.glyphWidth + 5
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.bright
        font.family: Theme.font
        font.pixelSize: Theme.barFontSize
        renderType: Text.NativeRendering
        opacity: root.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeInOut } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: event => root.wheel(event)
    }
}
