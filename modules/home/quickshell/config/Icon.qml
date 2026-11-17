// A tabler glyph: pass one of the Theme.i* codepoints as `text`.
import QtQuick
import "."

Text {
    color: Theme.text
    font.family: Theme.fontIcon
    font.pixelSize: Theme.iconSize
    renderType: Text.NativeRendering
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: Theme.durMed } }
}
