// Persistent 1-10 workspace markers, rendered as mono numerals inside a
// single widget card. State is conveyed through brightness + weight rather
// than colour — active = bright + bold, occupied = mid, empty = faint.
// Numbers (not dots) carry more information and read as deliberate.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "."

Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: Theme.barHeight - 8

    Rectangle {
        id: pill
        anchors.centerIn: parent
        height: parent.height
        implicitWidth: row.implicitWidth + Theme.widgetPad * 2
        radius: Theme.widgetRadius
        color: Theme.widget

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: 10
                delegate: Text {
                    id: cell
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) || null
                    readonly property bool active: Hyprland.focusedWorkspace
                        && Hyprland.focusedWorkspace.id === wsId
                    readonly property bool occupied: ws !== null

                    anchors.verticalCenter: parent.verticalCenter
                    text: wsId === 10 ? "0" : wsId.toString()
                    color: active ? Theme.text
                         : occupied ? Theme.dim
                                    : Theme.faint
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSize
                    font.weight: active ? Font.Bold : Font.Normal
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch(`workspace ${cell.wsId}`)
                    }
                }
            }
        }
    }
}
