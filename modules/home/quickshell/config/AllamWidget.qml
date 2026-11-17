import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "."

Item {
    id: root
    implicitWidth: pill.width
    implicitHeight: Theme.pillHeight

    readonly property bool busyPhase: Allam.phase === "starting" || Allam.phase === "restarting" || Allam.phase === "stopping"

    Slab {
        id: pill
        width: row.implicitWidth + 18
        height: Theme.pillHeight
        color: mouse.containsMouse || popup.open ? Theme.hover : Theme.surface

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.iBrain
                color: Allam.phase === "off" ? Theme.muted : Theme.text
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6; height: 6; radius: 3
                color: Allam.phase === "running" ? Theme.green
                     : root.busyPhase ? Theme.accent
                     : Theme.track
                Behavior on color { ColorAnimation { duration: Theme.durMed } }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.open = !popup.open
        }
    }

    PopupWindow {
        id: popup
        property bool open: false
        onOpenChanged: Allam.popupOpen = open

        anchor.item: pill
        anchor.rect.x: 0
        anchor.rect.y: pill.height + 10
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right

        implicitWidth: 264
        implicitHeight: card.height + Theme.cardShadow + 2
        color: "transparent"
        visible: open || card.opacity > 0

        HyprlandFocusGrab {
            windows: [popup, root.QsWindow.window]
            active: popup.open
            onCleared: popup.open = false
        }

        Slab {
            id: card
            width: 260
            height: body.implicitHeight + 28
            radius: Theme.cardRadius
            shadow: Theme.cardShadow
            opacity: popup.open ? 1 : 0
            transform: Translate {
                y: popup.open ? 0 : -8
                Behavior on y { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeInOut } }

            ColumnLayout {
                id: body
                x: 14; y: 14
                width: parent.width - 28
                spacing: 0

                RowLayout {
                    visible: Allam.phase === "off"
                    Layout.fillWidth: true
                    PText { text: "allam is off"; color: Theme.text; Layout.fillWidth: true }
                    IconButton { glyph: Theme.iPlay; onClicked: Allam.start() }
                }

                RowLayout {
                    visible: Allam.phase !== "off" && Allam.hasModel
                    Layout.fillWidth: true
                    Layout.bottomMargin: 14
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        PText {
                            Layout.fillWidth: true
                            text: Allam.model
                            color: Theme.bright
                            font.pixelSize: Theme.fontSize + 1
                            elide: Text.ElideRight
                        }
                        PText {
                            text: Allam.modelState === "loading" ? "loading…"
                                : (Allam.modelState === "sleeping" ? "sleeping · " : "")
                                  + "KV reserve " + (Allam.kvMib >= 0 ? (Allam.kvMib / 1024).toFixed(1) + " GB" : "—")
                            color: Theme.text
                            font.pixelSize: Theme.fontSizeSm
                        }
                    }
                    IconButton {
                        Layout.alignment: Qt.AlignTop
                        glyph: Theme.iEject
                        onClicked: Allam.unload()
                    }
                }

                PText {
                    visible: root.busyPhase && !Allam.hasModel
                    Layout.bottomMargin: 10
                    text: Allam.phase + "…"
                    color: Theme.accent
                    font.pixelSize: Theme.fontSizeSm
                }

                BatchSlider {
                    visible: Allam.phase !== "off"
                    Layout.fillWidth: true
                    name: "ubatch"
                    value: Allam.ubatch
                    pending: Allam.pendingUbatch
                    onCommit: v => Allam.setBatch("ubatch", v, Math.max(v, Allam.batch), false)
                }
                ForceRow { slider: "ubatch" }

                BatchSlider {
                    visible: Allam.phase !== "off"
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    name: "batch"
                    value: Allam.batch
                    pending: Allam.pendingBatch
                    onCommit: v => Allam.setBatch("batch", Math.min(Allam.ubatch, v), v, false)
                }
                ForceRow { slider: "batch" }

                ColumnLayout {
                    visible: Allam.phase !== "off" && !Allam.hasModel && Allam.models.length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    spacing: 0

                    Repeater {
                        model: Allam.models
                        delegate: Item {
                            id: mrow
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 30

                            Rectangle {
                                anchors.top: parent.top
                                width: parent.width
                                height: 1
                                color: Theme.sep
                            }
                            PText {
                                anchors.left: parent.left
                                anchors.right: play.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                textFormat: Text.StyledText
                                text: `<font color="${Theme.text}">${mrow.modelData.index}</font>&nbsp;&nbsp;${mrow.modelData.id}`
                                color: Theme.bright
                                elide: Text.ElideRight
                            }
                            Icon {
                                id: play
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: Theme.iPlay
                                font.pixelSize: 18
                                color: rowMouse.containsMouse ? Theme.accent : Theme.bright
                            }
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: Allam.phase === "running"
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Allam.load(mrow.modelData.index)
                            }
                        }
                    }
                }
            }
        }
    }

    component PText: Text {
        color: Theme.bright
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        renderType: Text.NativeRendering
    }

    component IconButton: Item {
        id: ib
        property string glyph
        signal clicked()
        implicitWidth: 22
        implicitHeight: 22
        Icon {
            anchors.centerIn: parent
            text: ib.glyph
            font.pixelSize: 20
            color: ibMouse.containsMouse ? Theme.accent : Theme.text
        }
        MouseArea {
            id: ibMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ib.clicked()
        }
    }

    component BatchSlider: ColumnLayout {
        id: bs
        property string name
        property int value
        property int pending
        readonly property int min: 128
        readonly property int max: 2048
        readonly property int step: 128
        property int dragValue: -1
        readonly property int shown: dragValue >= 0 ? dragValue : pending > 0 ? pending : value
        signal commit(int v)
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            PText { text: bs.name; color: Theme.text; font.pixelSize: Theme.fontSizeSm; Layout.fillWidth: true }
            PText {
                text: bs.shown
                font.pixelSize: Theme.fontSizeSm
                color: bs.dragValue < 0 && bs.pending > 0 ? Theme.accent : Theme.bright
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 14

            readonly property real frac: Math.max(0, Math.min(1, (bs.shown - bs.min) / (bs.max - bs.min)))

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 7
                radius: 4
                color: Theme.track
                border.color: Theme.ink
                border.width: 1

                Rectangle {
                    x: 1; y: 1
                    height: parent.height - 2
                    width: Math.max(0, (parent.width - 2) * parent.parent.frac)
                    radius: 3
                    color: Theme.text
                }
            }
            Rectangle {
                width: 14; height: 14; radius: 7
                anchors.verticalCenter: parent.verticalCenter
                x: parent.frac * parent.width - width / 2
                color: Theme.bright
                border.color: Theme.ink
                border.width: Theme.stroke
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                function pick(mx) {
                    const f = Math.max(0, Math.min(1, (mx - 6) / (width - 12)))
                    const v = bs.min + Math.round(f * (bs.max - bs.min) / bs.step) * bs.step
                    return Math.max(bs.min, Math.min(bs.max, v))
                }
                onPressed: m => bs.dragValue = pick(m.x)
                onPositionChanged: m => { if (pressed) bs.dragValue = pick(m.x) }
                onReleased: {
                    const v = bs.dragValue
                    bs.dragValue = -1
                    if (v >= 0 && v !== bs.value) bs.commit(v)
                }
                onCanceled: bs.dragValue = -1
            }
        }
    }

    component ForceRow: Item {
        id: fr
        property string slider
        readonly property bool on: Allam.refusedSlider === slider
        Layout.fillWidth: true
        implicitHeight: on ? 34 : 0
        clip: true
        Behavior on implicitHeight { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }

        Slab {
            id: fb
            y: 8
            width: forceText.implicitWidth + 20
            height: 22
            color: fbMouse.containsMouse ? Theme.accent : Theme.raised
            opacity: fr.on ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

            PText {
                id: forceText
                anchors.centerIn: parent
                text: "force"
                font.pixelSize: Theme.fontSizeSm
                color: fbMouse.containsMouse ? Theme.base : Theme.bright
            }
            MouseArea {
                id: fbMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Allam.setBatch(fr.slider, Allam.refusedUbatch, Allam.refusedBatch, true)
            }
        }
    }
}
