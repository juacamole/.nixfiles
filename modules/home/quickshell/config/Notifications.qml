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
    // The one card that animates in. Rebinding `live` recreates every delegate.
    property var lastAdded: null

    function toggle(): void { centerWin.visible = !centerWin.visible }

    // Must run before the Notification is destroyed: a dead QObject in a
    // JS-array model crashes Qt.
    function forget(notif): void {
        root.live = root.live.filter(n => n && n !== notif)
        root.history = root.history.filter(n => n && n !== notif)
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        keepOnReload: false

        onNotification: notif => {
            notif.tracked = true
            notif.closed.connect(() => root.forget(notif))
            root.lastAdded = notif
            root.live = [notif, ...root.live.filter(n => n)]
            const kept = [notif, ...root.history.filter(n => n)]
            kept.slice(root.historyLimit).forEach(n => { n.tracked = false })
            root.history = kept.slice(0, root.historyLimit)

            // Critical stays up until dismissed; battery-warn relies on that.
            if (notif.urgency === NotificationUrgency.Critical) return
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
                root.live = root.live.filter(n => n && n !== notif)
                destroy()
            }
        }
    }

    PanelWindow {
        visible: root.live.length > 0
        color: "transparent"
        anchors { top: true; right: true }
        margins { top: Theme.barMargin + Theme.barHeight + 8; right: Theme.barMargin }
        implicitWidth: 340 + Theme.cardShadow
        implicitHeight: stack.implicitHeight + Theme.cardShadow
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        ColumnLayout {
            id: stack
            anchors.fill: parent
            anchors.rightMargin: Theme.cardShadow
            anchors.bottomMargin: Theme.cardShadow
            spacing: 8

            Repeater {
                model: root.live
                delegate: NotificationCard {}
            }
        }
    }

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
            color: Theme.base
            border.color: Theme.ink
            border.width: Theme.stroke
            radius: 18

            ListView {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8
                clip: true
                model: root.history
                delegate: NotificationCard {}
            }
        }
    }

    // A plain Column inside: ColumnLayout collapses the wrapped Text to zero height.
    component NotificationCard: Rectangle {
        id: card
        required property var modelData
        readonly property var notif: modelData

        Layout.fillWidth: true
        Layout.preferredHeight: col.implicitHeight + 28
        implicitHeight: col.implicitHeight + 28
        radius: Theme.cardRadius
        color: Theme.surface
        border.color: card.notif?.urgency === NotificationUrgency.Critical ? Theme.red : Theme.ink
        border.width: Theme.stroke

        Rectangle {
            z: -1
            x: Theme.cardShadow
            y: Theme.cardShadow
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: Theme.ink
        }

        transform: Translate { id: slide }
        Component.onCompleted: {
            if (card.notif === root.lastAdded) {
                root.lastAdded = null
                enter.start()
            }
        }
        ParallelAnimation {
            id: enter
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: Theme.durMed; easing.type: Theme.easeInOut }
            NumberAnimation { target: slide; property: "x"; from: 32; to: 0; duration: 420; easing.type: Theme.easeOut }
        }

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 6

            Item {
                width: parent.width
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: (card.notif?.appName || "notification").toLowerCase()
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSm
                    font.letterSpacing: 1.2
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: closeBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: closeMouse.containsMouse ? Theme.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
                text: card.notif?.summary ?? ""
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Text {
                visible: (card.notif?.body ?? "").length > 0
                width: parent.width
                text: card.notif?.body ?? ""
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                textFormat: card.notif?.hasBodyMarkup ? Text.RichText : Text.PlainText
            }

            Row {
                width: parent.width
                spacing: 6
                visible: (card.notif?.actions?.length ?? 0) > 0

                Repeater {
                    model: card.notif?.actions ?? []
                    delegate: Rectangle {
                        required property var modelData
                        readonly property var action: modelData

                        height: 24
                        width: btnLabel.implicitWidth + 20
                        radius: 12
                        color: btnMouse.containsMouse ? Theme.accent : Theme.raised
                        border.color: Theme.ink
                        border.width: Theme.stroke
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }

                        Text {
                            id: btnLabel
                            anchors.centerIn: parent
                            text: action?.text ?? ""
                            color: btnMouse.containsMouse ? Theme.base : Theme.bright
                            font.family: Theme.font
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: btnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Handled here: most senders exit before the invoke signal reaches them.
                                if (action.identifier === "toggle-saver") {
                                    saverToggle.running = true
                                } else if (action.invoke) {
                                    action.invoke()
                                }
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
