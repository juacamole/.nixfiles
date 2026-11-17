// The one surface style: flat face, ink outline, hard offset shadow drawn
// down-right of the item (outside its bounds, so layouts size by the face
// alone). Children go on top of the face.
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
