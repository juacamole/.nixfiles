// Battery glyph drawn from rectangles: the inner bar fills with charge
// (green while charging, red below 20%). A small yellow leaf unfurls beside
// it while battery-saver is on. Hover for the percentage; click toggles
// battery-saver (BatterySaver.qml).
//
// Reads the first battery under /sys/class/power_supply via a poll — avoids
// guessing UPower API shape across QS versions, and self-hides on machines
// without a battery (pommes/desktop).
import QtQuick
import Quickshell.Io
import "."

StatusItem {
    id: root
    property int capacity: -1
    property string state: ""
    readonly property bool hasBattery: capacity >= 0
    readonly property bool charging: state === "Charging" || state === "Full"
    readonly property bool low: hasBattery && capacity < 20
    readonly property bool saver: BatterySaver.active

    visible: hasBattery
    glyphWidth: Math.round((24 + (saver ? 21 : 0)) * Theme.glyphScale)
    Behavior on glyphWidth { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }
    label: capacity + "%" + (charging ? " · charging" : "")
    onClicked: BatterySaver.toggle()

    Item {
        id: body
        width: 24
        height: 14
        anchors.verticalCenter: parent.verticalCenter
        // Authored at 20px-icon size, scaled up from the left edge.
        scale: Theme.glyphScale
        transformOrigin: Item.Left

        Rectangle {
            x: 1; y: 1
            width: 20; height: 12
            radius: 3
            color: "transparent"
            border.color: root.low ? Theme.red : Theme.text
            border.width: 1.5
        }
        Rectangle {
            x: 3.5; y: 3.5
            height: 7
            radius: 1
            width: Math.max(1, 15 * Math.max(0, Math.min(1, root.capacity / 100)))
            color: root.low ? Theme.red : root.charging ? Theme.green : Theme.text
            Behavior on width { NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easeOut } }
            Behavior on color { ColorAnimation { duration: Theme.durMed } }
        }
        Rectangle {
            x: 22; y: 4.5
            width: 1.8; height: 5
            radius: 0.5
            color: root.low ? Theme.red : Theme.text
        }
    }

    Icon {
        x: Math.round(27 * Theme.glyphScale)
        anchors.verticalCenter: parent.verticalCenter
        text: Theme.iLeaf
        font.pixelSize: Math.round(17 * Theme.glyphScale)
        color: Theme.yellow
        opacity: root.saver ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeInOut } }
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
                if (!isNaN(n) && n !== root.capacity) root.capacity = n
            }
        }
    }
    Process {
        id: statusP
        command: ["sh", "-c", "cat /sys/class/power_supply/*/status 2>/dev/null | head -n1"]
        stdout: SplitParser {
            onRead: line => {
                const s = line.trim()
                if (s !== root.state) root.state = s
            }
        }
    }
}
