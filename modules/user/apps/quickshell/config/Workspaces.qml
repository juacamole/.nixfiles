// One numbered dot per live workspace 1-10 (labelled 1..9, 0), in that
// order. Hyprland only keeps a workspace alive while it has windows or is
// focused, so empty ones have no dot. The focused dot is yellow. Click to
// switch.
//
// All ten slots always exist; a dead slot collapses to zero width and its
// dot pops away. That keeps delegates stable (no re-creation flicker when
// the workspace list changes) and lets neighbours slide instead of jump.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "."

Row {
    id: root
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    Repeater {
        model: 10
        delegate: Item {
            id: slot
            required property int index
            readonly property int wsId: index + 1
            readonly property bool alive:
                Hyprland.workspaces.values.some(w => w.id === slot.wsId)
            readonly property bool focused: root.focusedId === wsId

            width: alive ? Theme.dotSize + 7 : 0
            height: Theme.pillHeight + Theme.shadow
            Behavior on width { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }

            Slab {
                id: dot
                y: (Theme.pillHeight - Theme.dotSize) / 2
                width: Theme.dotSize
                height: Theme.dotSize
                color: slot.focused ? Theme.yellow
                     : mouse.containsMouse ? Theme.track
                     : Theme.raised
                scale: slot.alive ? 1 : 0
                opacity: slot.alive ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 360; easing.type: Theme.easeSpring; easing.overshoot: Theme.overshoot } }
                Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

                Text {
                    anchors.centerIn: parent
                    text: slot.wsId === 10 ? "0" : slot.wsId.toString()
                    color: slot.focused ? Theme.base : Theme.bright
                    font.family: Theme.font
                    font.pixelSize: Theme.barFontSize
                    font.weight: slot.focused ? Font.Medium : Font.Normal
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: Theme.durMed } }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: dot
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${slot.wsId}`)
            }
        }
    }
}
