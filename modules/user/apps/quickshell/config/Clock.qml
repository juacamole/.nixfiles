// "Su 15  00:01". Click switches to "15.11  00:01:23", click again to go
// back. Time is bright, the date half is the quieter label colour.
//
// Anti-flicker design:
//   * The two layouts are stacked and crossfade; each Text has a fixed width
//     from TextMetrics of its widest string, so Fredoka's proportional digits
//     never make the pill breathe minute to minute.
//   * Strings are derived from `_now`; the compact ones only change on minute
//     rollover, so most ticks are no-op assignments.
//   * Ticks every second only while the seconds are on screen.
//   * `renderType: Text.NativeRendering` on every Text.
import QtQuick
import "."

Item {
    id: root
    property bool detailed: false

    readonly property var days: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    property var _now: new Date()
    readonly property string dayText: days[_now.getDay()] + " " + Qt.formatDateTime(_now, "dd")
    readonly property string timeText: Qt.formatDateTime(_now, "HH:mm")
    readonly property string dateText: Qt.formatDateTime(_now, "dd.MM")
    readonly property string secText: Qt.formatDateTime(_now, "HH:mm:ss")

    TextMetrics { id: mDay;  font.family: Theme.font; font.pixelSize: Theme.barFontSize; text: "We 00" }
    TextMetrics { id: mTime; font.family: Theme.font; font.pixelSize: Theme.barFontSize; text: "00:00" }
    TextMetrics { id: mDate; font.family: Theme.font; font.pixelSize: Theme.barFontSize; text: "00.00" }
    TextMetrics { id: mSec;  font.family: Theme.font; font.pixelSize: Theme.barFontSize; text: "00:00:00" }

    readonly property int gap: 14
    readonly property real compactWidth: Math.ceil(mDay.advanceWidth + gap + mTime.advanceWidth) + 2 * 26
    readonly property real detailedWidth: Math.ceil(mDate.advanceWidth + gap + mSec.advanceWidth) + 2 * 26

    implicitWidth: detailed ? detailedWidth : compactWidth
    implicitHeight: Theme.pillHeight
    Behavior on implicitWidth { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }

    Timer {
        interval: root.detailed ? 1000 : 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._now = new Date()
    }
    onDetailedChanged: _now = new Date()

    Slab {
        anchors.fill: parent
        color: mouse.containsMouse ? Theme.hover : Theme.surface

        Row {
            anchors.centerIn: parent
            spacing: root.gap
            opacity: root.detailed ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeInOut } }
            ClockText { width: mDay.advanceWidth; text: root.dayText; color: Theme.text }
            ClockText { width: mTime.advanceWidth; text: root.timeText; color: Theme.bright }
        }

        Row {
            anchors.centerIn: parent
            spacing: root.gap
            opacity: root.detailed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeInOut } }
            ClockText { width: mDate.advanceWidth; text: root.dateText; color: Theme.text }
            ClockText { width: mSec.advanceWidth; text: root.secText; color: Theme.bright }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.detailed = !root.detailed
    }

    component ClockText: Text {
        horizontalAlignment: Text.AlignHCenter
        font.family: Theme.font
        font.pixelSize: Theme.barFontSize
        renderType: Text.NativeRendering
    }
}
