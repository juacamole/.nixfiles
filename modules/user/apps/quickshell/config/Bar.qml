// Floating pills along the top edge, no bar background — the wallpaper
// shows between them. Three independently-anchored clusters:
//   left   workspace dots + allam brain pill
//   center clock
//   right  one status pill: coffee (idle inhibitor), RAM ring, volume,
//          wifi, battery
// The clock is anchored to the panel's geometric center, NOT positioned by a
// layout, so when the side clusters change width (hover reveals, workspace
// dots appearing) it cannot shift.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: root
    // Variants in shell.qml injects modelData for each Quickshell.screens item;
    // forward it to the PanelWindow's screen.
    property var modelData
    screen: modelData

    // Reserve the top margin + pill strip; hyprland's gaps_out supplies the
    // space between the pills and the tiles below.
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.barMargin
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    // Auto derives the exclusion from anchors + implicit size when 3 anchors
    // are connected. `Normal` would require an explicit exclusionZone.
    WlrLayershell.exclusionMode: ExclusionMode.Auto
    WlrLayershell.namespace: "kuan-bar"

    Item {
        id: strip
        anchors.fill: parent
        anchors.topMargin: Theme.barMargin
        anchors.leftMargin: Theme.barMargin + 4
        anchors.rightMargin: Theme.barMargin + 4

        // Entrance: the pills drop in from above the edge and fade in. Only
        // the visual moves — the exclusion zone is set from frame one, so
        // tiled windows don't reflow mid-animation.
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
