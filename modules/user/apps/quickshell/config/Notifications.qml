// Implements the freedesktop notification spec via NotificationServer. Pops
// each notification as a transient top-right card; stacks into a center when
// toggled open via IPC.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "."

Scope {
    id: root

    property var live: []      // currently-popping
    property var history: []   // last N retained
    readonly property int historyLimit: 50

    function toggle(): void { centerWin.visible = !centerWin.visible }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true
            root.live = [notif, ...root.live]
            root.history = [notif, ...root.history].slice(0, root.historyLimit)

            // Auto-expire from the live stack. Notification center retains it.
            const ms = notif.expireTimeout > 0 ? notif.expireTimeout : 5000
            expireTimerComponent.createObject(root, { notif: notif, interval: ms })
        }
    }

    Component {
        id: expireTimerComponent
        Timer {
            property var notif
            running: true
            repeat: false
            onTriggered: {
                root.live = root.live.filter(n => n !== notif)
                destroy()
            }
        }
    }

    // Live popups — top-right stack
    PanelWindow {
        visible: root.live.length > 0
        color: "transparent"
        anchors { top: true; right: true }
        margins { top: Theme.barMargin + Theme.barHeight + 8; right: Theme.barMargin }
        implicitWidth: 340
        implicitHeight: stack.implicitHeight
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        ColumnLayout {
            id: stack
            anchors.fill: parent
            spacing: 8

            Repeater {
                model: root.live
                delegate: NotificationCard {}
            }
        }
    }

    // Notification center — opened via qsctl
    PanelWindow {
        id: centerWin
        visible: false
        color: "transparent"
        anchors { top: true; right: true; bottom: true }
        margins { top: Theme.barMargin + Theme.barHeight + 8; right: Theme.barMargin; bottom: Theme.barMargin }
        implicitWidth: 360
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: Theme.bg
            border.color: Theme.widgetHi
            border.width: 1
            radius: Theme.widgetRadius

            ListView {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                clip: true
                model: root.history
                delegate: NotificationCard {}
            }
        }
    }

    // Plain Column + explicit widths instead of ColumnLayout. ColumnLayout
    // tried to derive height from children whose height depends on wrap
    // width, which depends on parent height → cycle that collapses Text to
    // zero height (the "black box, no text" symptom).
    component NotificationCard: Rectangle {
        id: card
        // Repeater injects `modelData` (the Notification object). Components
        // in Qt 6 must declare the property — without it, `modelData` is
        // undefined inside the delegate and every binding on the notification
        // returns undefined (renders as empty text → black box).
        required property var modelData
        readonly property var notif: modelData

        // Width is supplied by the outer ColumnLayout in the parent
        // PanelWindow via Layout.fillWidth. Height = content + padding.
        Layout.fillWidth: true
        Layout.preferredHeight: col.implicitHeight + 24
        implicitHeight: col.implicitHeight + 24
        radius: Theme.widgetRadius
        color: "#1a1a1a"
        border.color: "#3a3a3a"
        border.width: 1

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 6

            // Header: app name + close button
            Item {
                width: parent.width
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: (card.notif.appName || "notification").toLowerCase()
                    color: Theme.dim
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.letterSpacing: 0.5
                    renderType: Text.NativeRendering
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 2
                    color: closeMouse.containsMouse ? Theme.widgetHi : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                        renderType: Text.NativeRendering
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Drop from our own arrays first (visual feedback is
                        // instant); then tell the server. `dismiss()` alone
                        // doesn't remove the entry from `live`/`history`.
                        onClicked: {
                            root.live = root.live.filter(n => n !== card.notif)
                            root.history = root.history.filter(n => n !== card.notif)
                            if (card.notif && card.notif.dismiss) card.notif.dismiss()
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: card.notif.summary
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.weight: Font.Bold
                renderType: Text.NativeRendering
                wrapMode: Text.WordWrap
            }

            Text {
                visible: card.notif.body.length > 0
                width: parent.width
                text: card.notif.body
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 12
                renderType: Text.NativeRendering
                wrapMode: Text.WordWrap
                textFormat: card.notif.hasBodyMarkup ? Text.RichText : Text.PlainText
            }

            // Action buttons (freedesktop notification "actions"). Senders like
            // notify-send's --action attach these; we render them as clickable
            // pills. For a handful of known identifiers (battery-saver toggle)
            // we run the local handler ourselves — most notify-send-based
            // senders exit before invoke()'s DBus signal reaches anyone.
            Row {
                width: parent.width
                spacing: 6
                visible: card.notif.actions && card.notif.actions.length > 0

                Repeater {
                    model: card.notif.actions
                    delegate: Rectangle {
                        required property var modelData
                        readonly property var action: modelData

                        height: 22
                        width: btnLabel.implicitWidth + 16
                        radius: 2
                        color: btnMouse.containsMouse ? Theme.widgetHi : "#242424"
                        border.color: "#3a3a3a"
                        border.width: 1

                        Text {
                            id: btnLabel
                            anchors.centerIn: parent
                            text: action.text
                            color: Theme.text
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (action.identifier === "toggle-saver") {
                                    saverToggle.running = true
                                } else if (action.invoke) {
                                    action.invoke()
                                }
                                // Consistent dismiss behaviour with the × button.
                                root.live = root.live.filter(n => n !== card.notif)
                                root.history = root.history.filter(n => n !== card.notif)
                                if (card.notif && card.notif.dismiss) card.notif.dismiss()
                            }
                        }

                        Process {
                            id: saverToggle
                            command: ["battery-saver", "toggle"]
                        }
                    }
                }
            }
        }
    }
}
