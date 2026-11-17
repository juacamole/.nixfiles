import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

Scope {
    id: root

    function open(): void  { win.shown = true; entry.text = ""; entry.forceActiveFocus() }
    function close(): void { win.shown = false }
    function toggle(): void { win.shown ? close() : open() }

    PanelWindow {
        id: win
        property bool shown: false

        visible: shown || content.opacity > 0
        color: "transparent"
        anchors { top: true; left: true; right: true; bottom: true }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: win.shown ? 0.45 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeInOut } }
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Item {
            id: content
            anchors.fill: parent
            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Theme.easeInOut } }

            Slab {
                id: panel
                anchors.centerIn: parent
                width: 560
                height: 420
                radius: 20
                shadow: Theme.cardShadow + 1
                scale: win.shown ? 1 : 0.96
                Behavior on scale { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }
                transform: Translate {
                    y: win.shown ? 0 : 10
                    Behavior on y { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: height / 2
                        color: Theme.base
                        border.width: Theme.stroke
                        border.color: entry.activeFocus ? Theme.accent : Theme.ink
                        Behavior on border.color { ColorAnimation { duration: Theme.durMed } }

                        TextInput {
                            id: entry
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.bright
                            font.family: Theme.font
                            font.pixelSize: 14
                            focus: true
                            clip: true

                            onTextChanged: list.currentIndex = 0
                            Keys.onEscapePressed: root.close()
                            Keys.onDownPressed:   list.incrementCurrentIndex()
                            Keys.onUpPressed:     list.decrementCurrentIndex()
                            Keys.onReturnPressed: list.launchCurrent()
                            Keys.onEnterPressed:  list.launchCurrent()
                        }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            verticalAlignment: Text.AlignVCenter
                            text: "Search applications…"
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: 14
                            visible: entry.text.length === 0
                        }
                    }

                    ListView {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        currentIndex: 0
                        keyNavigationWraps: true

                        highlight: Rectangle {
                            radius: 10
                            color: Theme.raised
                            border.color: Theme.ink
                            border.width: 1
                        }
                        highlightFollowsCurrentItem: true
                        highlightMoveDuration: 220
                        highlightMoveVelocity: -1
                        highlightResizeDuration: 0
                        highlightResizeVelocity: -1

                        model: {
                            const q = entry.text.toLowerCase()
                            const entries = DesktopEntries.applications.values
                                .filter(e => !e.noDisplay)
                                .filter(e => q.length === 0 || e.name.toLowerCase().includes(q))
                            entries.sort((a, b) => a.name.localeCompare(b.name))
                            return entries
                        }

                        function launchCurrent(): void {
                            const item = model[currentIndex]
                            if (!item) return
                            item.execute()
                            root.close()
                        }

                        delegate: Item {
                            id: card
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            height: 36

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10

                                Text {
                                    text: card.modelData.name
                                    color: card.ListView.isCurrentItem ? Theme.bright : Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                                }
                                Text {
                                    text: card.modelData.genericName || ""
                                    color: Theme.muted
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: list.currentIndex = card.index
                                onClicked: { list.currentIndex = card.index; list.launchCurrent() }
                            }
                        }
                    }
                }
            }
        }
    }
}
