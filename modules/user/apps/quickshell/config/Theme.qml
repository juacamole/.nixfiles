pragma Singleton
import QtQuick

// Severe grayscale. Single typeface (JetBrainsMono Nerd Font). No accent
// colour — workspace activity / state is conveyed through brightness and
// weight, not hue. Sharp 2-3px corners, full opacity (translucency is the
// AI-default tell). Designed for restraint, not decoration.
QtObject {
    // Surfaces — five steps of grey, near-black up to off-white.
    readonly property color bg:       "#0d0d0d"   // panel-less bar wallpaper bleed if any
    readonly property color widget:   "#161616"   // widget card bg
    readonly property color widgetHi: "#242424"   // hover / active widget card
    readonly property color rule:     "#2a2a2a"   // dividers, if used

    // Text — three steps.
    readonly property color text:     "#d4d4d4"   // primary
    readonly property color dim:      "#8a8a8a"   // secondary (occupied workspace, etc.)
    readonly property color faint:    "#5a5a5a"   // tertiary (empty workspace, idle)

    // Reserved for genuine alerts only. Use sparingly — never as decoration.
    readonly property color warn:     "#b3a371"   // low battery, etc.
    readonly property color crit:     "#c2392f"   // critical battery, mute, etc.

    // Geometry — sharp, not pill-shaped. Small radius reads as crafted; the
    // 12-16px rounded look reads as Catppuccin-default.
    readonly property int barHeight:    30
    readonly property int barMargin:    10
    readonly property int widgetPad:    10
    readonly property int widgetGap:    6
    readonly property int widgetRadius: 3

    // One typeface, two sizes. Mono everywhere — tabular figures, no reflow
    // on minute change, and consistent rhythm across all widgets.
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontUi:   fontMono   // alias for callsites that still ask for "ui"
    readonly property int    fontSize: 12
    readonly property int    fontSizeSm: 10
}
