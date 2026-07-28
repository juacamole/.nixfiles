// Centered overlay launcher backed by DesktopEntries. Type to filter, arrows
// to navigate, Enter to launch, Esc to close. Opened via IPC from hyprland.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

Scope {
    id: root

    function open(): void  { win.visible = true; entry.text = ""; entry.forceActiveFocus() }
    function close(): void { win.visible = false }
    function toggle(): void { win.visible ? close() : open() }

    PanelWindow {
        id: win
        visible: false
        color: "transparent"
        anchors { top: true; left: true; right: true; bottom: true }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        // Dim backdrop
        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 520
            height: 380
            radius: Theme.widgetRadius
            color: Theme.bg
            border.color: Theme.widgetHi
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Search entry
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Theme.widgetRadius
                    color: Theme.widget

                    TextInput {
                        id: entry
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.fontUi
                        font.pixelSize: 14
                        focus: true
                        clip: true

                        Keys.onEscapePressed: root.close()
                        Keys.onDownPressed:   list.incrementCurrentIndex()
                        Keys.onUpPressed:     list.decrementCurrentIndex()
                        Keys.onReturnPressed: list.launchCurrent()
                        Keys.onEnterPressed:  list.launchCurrent()
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        text: "Search applications…"
                        color: Theme.faint
                        font.family: Theme.fontUi
                        font.pixelSize: 14
                        visible: entry.text.length === 0
                    }
                }

                // Results
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    currentIndex: 0
                    keyNavigationWraps: true

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

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 32
                        radius: 0
                        color: ListView.isCurrentItem ? Theme.widgetHi : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: card.modelData.name
                                color: Theme.text
                                font.family: Theme.fontUi
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: card.modelData.genericName || ""
                                color: Theme.faint
                                font.family: Theme.fontUi
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { list.currentIndex = card.index; list.launchCurrent() }
                        }
                    }
                }
            }
        }
    }
}
