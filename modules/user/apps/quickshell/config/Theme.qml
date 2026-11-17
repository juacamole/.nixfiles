pragma Singleton
import QtQuick

// "Ink & cream" — flat, opaque, neo-brutalist. Every surface is a solid
// slab with a near-black ink outline and a hard offset shadow (see
// Slab.qml); nothing is translucent, so hyprland no longer blurs the shell
// layers. Palette pulled from the wallpaper (stormy night-blue). One accent
// marks focus / "on" — still named `yellow` so widgets need no edits, but
// now the pale periwinkle of the wind streaks; green (sea-glass) means a
// daemon is healthy, red means muted / failing.
//
// The bar's anti-flicker rules still apply everywhere: NativeRendering for
// bar text, fixed/padded widths, no spurious re-assigns. Animations act on
// opacity / colour / position / width — never on scale of NativeRendering
// text.
QtObject {
    // Surfaces
    readonly property color base:    "#121a24"   // desktop / overlay backdrop
    readonly property color surface: "#1a2533"   // pills, cards, panels
    readonly property color raised:  "#273648"   // workspace dots, chips
    readonly property color track:   "#2e4058"   // slider + ring tracks, "off" dot
    readonly property color sep:     "#24324a"   // hairline row separators
    readonly property color hover:   "#213044"   // pill face under the pointer
    readonly property color ink:     "#080c12"   // outlines + hard shadows

    // Text
    readonly property color text:   "#8fa6bf"    // labels, icons at rest
    readonly property color bright: "#e8eef2"    // values, emphasis (mask white)
    readonly property color muted:  "#5a7089"    // off / disabled / captions

    // Accents
    readonly property color yellow: "#aebcf0"    // focus, "kept awake", starting (periwinkle)
    readonly property color green:  "#8fc7b0"    // running / charging
    readonly property color red:    "#e0948a"    // muted, low battery, errors

    // Geometry. Text ~x1.2 the mockup; bar icons deliberately much larger.
    readonly property int pillHeight: 42     // tall enough for 35px icons
    readonly property int dotSize:    36     // workspace dots
    readonly property int shadow:     2      // hard shadow offset, pills
    readonly property int cardShadow: 3      // hard shadow offset, cards
    readonly property real stroke:    1.5    // ink outline width
    readonly property int pillPad:    11
    readonly property int pillGap:    12     // between icons inside a pill
    readonly property int widgetGap:  8      // between pills
    readonly property int cardRadius: 14
    readonly property int barMargin:  8
    // Visible bar strip: pill plus its shadow.
    readonly property int barHeight:  pillHeight + shadow

    // Type. Fredoka for everything; tabler-icons for glyphs (both shipped
    // by default.nix).
    readonly property string font:     "Fredoka"
    readonly property string fontIcon: "tabler-icons"
    readonly property int fontSize:   13
    readonly property int fontSizeSm: 12
    readonly property int barFontSize: 17   // clock, workspace numbers, hover values
    readonly property int iconSize:   35
    // Drawn glyphs (RAM ring, battery) are authored at a 20px icon size
    // and scaled by this to match.
    readonly property real glyphScale: iconSize / 20

    // Tabler glyphs (webfont 3.42.0 codepoints).
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

    // Motion — unhurried, eased, occasionally a whisper of overshoot.
    readonly property int durFast: 150
    readonly property int durMed:  280
    readonly property int durSlow: 480
    readonly property int easeOut:    Easing.OutCubic
    readonly property int easeInOut:  Easing.InOutQuad
    readonly property int easeSpring: Easing.OutBack
    readonly property real overshoot: 1.4
}
