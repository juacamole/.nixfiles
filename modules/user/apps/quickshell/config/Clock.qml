// Click swaps between "HH:mm" and "ddd dd MMM · HH:mm".
//
// Anti-flicker design:
//   * We poll wall time every 5s into `_now`, then derive `displayText` from
//     it. QML compares string values on assignment, so the Text.text binding
//     only changes when the formatted minute actually rolls over — most polls
//     are no-ops and don't trigger a repaint.
//   * `renderType: Text.NativeRendering` uses FreeType directly; Qt's default
//     distance-field renderer caused a one-frame styling glitch on each
//     Text.text update.
//   * Fixed widths per mode so layout never reflows.
import QtQuick
import "."

Item {
    id: root
    property bool detailed: false

    readonly property int compactWidth: 72
    readonly property int detailedWidth: 200

    implicitWidth: detailed ? detailedWidth : compactWidth
    implicitHeight: Theme.barHeight - 8
    Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    property var _now: new Date()
    readonly property string displayText: Qt.formatDateTime(
        _now,
        detailed ? "ddd dd MMM · HH:mm" : "HH:mm"
    )

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.widgetRadius
        color: mouse.containsMouse ? Theme.widgetHi : Theme.widget
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        color: Theme.text
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontSize
        renderType: Text.NativeRendering
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.detailed = !root.detailed
    }
}
