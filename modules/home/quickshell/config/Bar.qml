import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: root
    property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.barMargin
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Auto
    WlrLayershell.namespace: "kuan-bar"

    Item {
        id: strip
        anchors.fill: parent
        anchors.topMargin: Theme.barMargin
        anchors.leftMargin: Theme.barMargin + 4
        anchors.rightMargin: Theme.barMargin + 4

        opacity: 0
        transform: Translate { id: drop; y: -Theme.barHeight }
        Component.onCompleted: intro.start()
        ParallelAnimation {
            id: intro
            NumberAnimation { target: strip; property: "opacity"; to: 1; duration: Theme.durSlow; easing.type: Theme.easeOut }
            NumberAnimation { target: drop; property: "y"; to: 0; duration: Theme.durSlow + 120; easing.type: Theme.easeSpring; easing.overshoot: 1.2 }
        }

        Row {
            anchors.left: parent.left
            y: 0
            spacing: 4

            Workspaces {}
            AllamWidget {}
        }

        // Anchored to the centre, not laid out, so the side clusters cannot push it.
        Clock {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
        }

        Slab {
            id: status
            anchors.right: parent.right
            y: 0
            height: Theme.pillHeight
            width: tray.implicitWidth + Theme.pillPad * 2

            Row {
                id: tray
                x: Theme.pillPad
                height: parent.height
                spacing: Theme.pillGap

                IdleLockToggle {}
                Memory {}
                Volume {}
                Network {}
                Battery {} // self-hides when no battery
            }
        }
    }
}
