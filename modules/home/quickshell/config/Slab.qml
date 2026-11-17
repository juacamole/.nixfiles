// The one surface style. The shadow is drawn outside the item's bounds, so
// layouts size by the face alone.
import QtQuick
import "."

Item {
    id: root
    property color color: Theme.surface
    property color borderColor: Theme.ink
    property real radius: height / 2
    property int shadow: Theme.shadow

    default property alias content: face.data

    Rectangle {
        x: root.shadow
        y: root.shadow
        width: root.width
        height: root.height
        radius: root.radius
        color: Theme.ink
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.color: root.borderColor
        border.width: Theme.stroke
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
    }
}
