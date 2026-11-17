// RAM ring: the arc fills clockwise from 12 o'clock as memory fills
// (MemTotal - MemAvailable). Hover for the exact percentage.
import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import "."

StatusItem {
    id: root
    property int percent: 0
    glyphWidth: Math.round(19 * Theme.glyphScale)
    label: percent + "%"

    Shape {
        anchors.centerIn: parent
        width: 19
        height: 19
        scale: Theme.glyphScale
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Theme.track
            strokeWidth: 2.8
            fillColor: "transparent"
            PathAngleArc { centerX: 9.5; centerY: 9.5; radiusX: 7.2; radiusY: 7.2; startAngle: 0; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: root.percent >= 90 ? Theme.red : Theme.text
            strokeWidth: 2.8
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                id: arc
                centerX: 9.5; centerY: 9.5; radiusX: 7.2; radiusY: 7.2
                startAngle: -90
                sweepAngle: 360 * root.percent / 100
                Behavior on sweepAngle { NumberAnimation { duration: Theme.durSlow; easing.type: Theme.easeOut } }
            }
        }
    }

    Timer {
        interval: BatterySaver.active ? 15000 : 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Process {
        id: poll
        command: ["awk", "/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t) print int((t-a)*100/t+0.5)}", "/proc/meminfo"]
        stdout: SplitParser {
            onRead: line => {
                const n = parseInt(line, 10)
                if (!isNaN(n) && n !== root.percent) root.percent = n
            }
        }
    }
}
