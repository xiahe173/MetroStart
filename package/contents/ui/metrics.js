// Geometry, colours and typography of the Windows 10 style Start menu.
// Design constants of the Windows 10 style menu (reference: 2560x1440 at scale 1.0)
// and cross-checked against ExplorerPatcher / ep_starttiledata constants.
.pragma library

var cell = 90
var gap = 6
var pitch = 96
var groupWidth = 570
var groupGapX = 205
var groupGapY = 96

var backdropColor = "#2A2A2A"
var backdropOpacity = 0.8

var tileFill = "#FFFFFF"
var tileFillOpacity = 0.10

var fontFamily = "Noto Sans"

var labelSize = 17
var labelX = 12
var labelBaseline = 173
var labelLineGap = 23

var groupTitleSize = 20
var groupTitleOffsetY = -42

// Sidebar
var sidebarCollapsedWidth = 56
var sidebarExpandedWidth = 386
var sidebarAccentWidth = 6
var sidebarAccentColor = "#6C91B5"
var sidebarItemHeight = 72
var sidebarItemsTop = 78
var sidebarTitleSize = 24
var sidebarItemSize = 23
var sidebarSelectedColor = "#B8D6E8"
var sidebarItemColor = "#9FB6C4"
var sidebarPanelColor = "#222222"

// Application list
var appLetterX = 691
var appLetterSize = 26
var appColumns = [779, 1145, 1513]
var appIconSize = 48
var appRowPitch = 66
var appNameOffsetX = 63
var appNameSize = 21

// Flyouts
var menuPanelColor = "#232323"
var menuItemSize = 19
var menuItemHeight = 49
// Vertical offset from an ink box top to the corresponding Text item top.
var titleInkOffset = 5
var appNameInkOffset = 5
var letterInkOffset = 6
var menuItemInkOffset = 5

// The reference renders CJK label glyphs 1 px higher and 1 px wider per glyph
// than the Latin text of the same nominal size.
var cjkBaselineShift = 1
var cjkLetterSpacing = 1

var appSectionGap = 48
