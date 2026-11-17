pragma Singleton
import QtQuick

// Flat and opaque: every surface is a Slab with an ink outline and a hard
// shadow. The palette comes from the wallpaper and is mirrored in
// ../../palette.nix (`night`); change both together.
QtObject {
    // Surfaces
    readonly property color base:    "#121a24"   // overlay backdrop
    readonly property color surface: "#1a2533"   // pills, cards, panels
    readonly property color raised:  "#273648"   // workspace dots, chips
    readonly property color track:   "#2e4058"   // slider and ring tracks
    readonly property color sep:     "#24324a"   // row separators
    readonly property color hover:   "#213044"
    readonly property color ink:     "#080c12"   // outlines, hard shadows

    // Text
    readonly property color text:   "#8fa6bf"    // labels, icons at rest
    readonly property color bright: "#e8eef2"    // values, emphasis
    readonly property color muted:  "#5a7089"    // off, disabled

    // Accents
    readonly property color accent: "#aebcf0"    // focus, "on", in progress
    readonly property color green:  "#8fc7b0"    // running, charging
    readonly property color red:    "#e0948a"    // muted, low battery, errors

    // Geometry
    readonly property int pillHeight: 42
    readonly property int dotSize:    36
    readonly property int shadow:     2      // pills
    readonly property int cardShadow: 3      // cards
    readonly property real stroke:    1.5
    readonly property int pillPad:    11
    readonly property int pillGap:    12     // between icons inside a pill
    readonly property int widgetGap:  8      // between pills
    readonly property int cardRadius: 14
    readonly property int barMargin:  8
    readonly property int barHeight:  pillHeight + shadow

    // Type
    readonly property string font:     "Fredoka"
    readonly property string fontIcon: "tabler-icons"
    readonly property int fontSize:   13
    readonly property int fontSizeSm: 12
    readonly property int barFontSize: 17
    readonly property int iconSize:   35
    // Drawn glyphs (RAM ring, battery) are authored for a 20px icon.
    readonly property real glyphScale: iconSize / 20

    // Tabler glyphs (webfont 3.42.0 codepoints)
    readonly property string iBrain:     ""
    readonly property string iCoffee:    ""
    readonly property string iVolume:    ""   // two waves
    readonly property string iVolume1:   ""   // one wave
    readonly property string iVolumeOff: ""
    readonly property string iWifi:      ""
    readonly property string iWifiOff:   ""
    readonly property string iWired:     ""
    readonly property string iEject:     ""
    readonly property string iPlay:      ""
    readonly property string iLeaf:      ""
    readonly property string iSearch:    ""
    readonly property string iX:         ""
    readonly property string iSun:       ""

    // Motion
    readonly property int durFast: 150
    readonly property int durMed:  280
    readonly property int durSlow: 480
    readonly property int easeOut:    Easing.OutCubic
    readonly property int easeInOut:  Easing.InOutQuad
    readonly property int easeSpring: Easing.OutBack
    readonly property real overshoot: 1.4
}
