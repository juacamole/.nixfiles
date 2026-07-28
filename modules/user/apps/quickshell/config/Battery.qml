// Reads the first battery under /sys/class/power_supply via a 10s poll.
// Avoids guessing UPower API shape across QS versions, and self-hides on
// machines without a battery (pommes/desktop).
//
// Click toggles battery-saver mode (see BatterySaver.qml singleton). When
// saver is active the bolt/battery glyph tints Theme.warn (gold). The
// percentage text keeps its own crit/dim binding so the "low battery" signal
// is never stolen by the "saver on" signal.
import QtQuick
import Quickshell.Io
import "."

Item {
    id: root
    property int capacity: -1
    property string state: ""
    readonly property bool hasBattery: capacity >= 0
    readonly property bool charging: state === "Charging" || state === "Full"

    visible: hasBattery
    implicitWidth: visible ? row.implicitWidth + Theme.widgetPad * 2 : 0
    implicitHeight: Theme.barHeight - 8

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: hover.containsMouse ? Theme.widgetHi : Theme.widget
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.charging ? "" : "" // nf bolt / battery
            // Priority: low battery > saver active > normal dim. Never re-assign
            // `text` based on saver state — that would reflow the row.
            color: root.capacity < 20 ? Theme.crit
                 : BatterySaver.active ? Theme.warn
                 : Theme.dim
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSize
            renderType: Text.NativeRendering
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            // Pad to 4 chars so the row doesn't reflow when crossing 9%/10%/100%.
            text: (root.capacity + "%").padStart(4, " ")
            color: root.capacity < 20 ? Theme.crit : Theme.text
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSize
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: BatterySaver.toggle()
    }

    // Slow the sysfs poll in saver mode. 60s is still faster than any human
    // reaction to a charge-state change during idle.
    Timer {
        interval: BatterySaver.active ? 60000 : 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: { capP.running = true; statusP.running = true }
    }

    Process {
        id: capP
        // First battery directory under /sys/class/power_supply with a capacity file.
        command: ["sh", "-c", "cat /sys/class/power_supply/*/capacity 2>/dev/null | head -n1"]
        stdout: SplitParser {
            onRead: line => {
                const n = parseInt(line, 10)
                if (!isNaN(n)) root.capacity = n
            }
        }
    }
    Process {
        id: statusP
        command: ["sh", "-c", "cat /sys/class/power_supply/*/status 2>/dev/null | head -n1"]
        stdout: SplitParser {
            onRead: line => { root.state = line.trim() }
        }
    }
}
