// Floating "island" top bar. Three columns: workspaces | clock (centered) |
// system tray (volume, network, battery if present).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: root
    // Variants in shell.qml injects modelData for each Quickshell.screens item;
    // forward it to the PanelWindow's screen.
    property var modelData
    screen: modelData

    // Panel covers the full top strip including the floating-island gaps on
    // all sides. That way the exclusion zone (panel height) reserves enough
    // room for the bar + the gap below it, so hyprland tiles never slip
    // underneath. The visible island lives inset by barMargin on every side.
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.barMargin * 2
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    // Auto derives the exclusion from anchors + margins + implicit size when 3
    // anchors are connected (top+left+right here). `Normal` would require an
    // explicit `exclusionZone`; without one, nothing is reserved and tiled
    // windows slide under the bar.
    WlrLayershell.exclusionMode: ExclusionMode.Auto
    WlrLayershell.namespace: "kuan-bar"

    // Three independently-anchored clusters. Critically the Clock is anchored
    // to the bar's geometric center, NOT positioned by a RowLayout — so when
    // Battery / Volume / Workspaces change width (digits, bold weight on
    // active workspace, etc.), the Clock cannot shift. That was the source of
    // the per-update "glitch".
    Item {
        id: row
        anchors.fill: parent
        anchors.margins: Theme.barMargin

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.widgetGap

            Workspaces {}
            IdleLockToggle {} // idle-lock on/off, just right of workspaces
        }

        Clock {
            anchors.centerIn: parent
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.widgetGap

            Volume {}
            Network {}
            BatterySaverIndicator {} // hides when saver mode is off
            Battery {} // self-hides when no battery
        }
    }
}
