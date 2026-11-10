// A single tile: translucent fill, icon, labels, reveal border and spotlight.
import QtQuick
import Qt5Compat.GraphicalEffects
import "metrics.js" as Metrics

Item {
    id: tile
    property var tileData: null
    property real pointerX: -1
    property real pointerY: -1
    property bool pointerInside: false
    signal activated(var entry)

    width: tileData ? tileData.w : 0
    height: tileData ? tileData.h : 0
    x: tileData ? tileData.x : 0
    y: tileData ? tileData.y : 0

    readonly property var labelLines: {
        if (!tileData || !tileData.label)
            return []
        return typeof tileData.label === "string" ? [tileData.label] : tileData.label
    }
    readonly property bool twoLines: labelLines.length > 1

    readonly property bool hovered: hover.hovered
    readonly property real localX: pointerX - x
    readonly property real localY: pointerY - y
    readonly property real distance: Math.hypot(pointerX - (x + width / 2),
                                                pointerY - (y + height / 2))
    // Reveal: tiles close to the pointer light up, the hovered tile strongest.
    readonly property real reveal: pointerInside ? Math.max(0, 1 - distance / 360) : 0

    Rectangle {
        anchors.fill: parent
        color: Metrics.tileFill
        opacity: Metrics.tileFillOpacity
    }

    // Soft radial spotlight, only for the tile under the pointer.
    RadialGradient {
        anchors.fill: parent
        visible: tile.hovered
        horizontalOffset: tile.localX - width / 2
        verticalOffset: tile.localY - height / 2
        horizontalRadius: 220
        verticalRadius: 220
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#16FFFFFF" }
            GradientStop { position: 0.55; color: "#08FFFFFF" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    readonly property var iconRect: {
        if (!tileData || !tileData.iconRect)
            return null
        const r = tileData.iconRect
        return Array.isArray(r) ? { x: r[0], y: r[1], w: r[2], h: r[3] }
                                : { x: r.x, y: r.y, w: r.w, h: r.h }
    }
    readonly property int fallbackIconSize: Math.round(Math.min(width, height)
                                                       * (labelLines.length > 0 ? 0.42 : 0.5))

    AppIcon {
        visible: !!(tile.tileData && tile.tileData.icon)
        source: (tile.tileData && tile.tileData.icon) ? tile.tileData.icon : ""
        x: tile.iconRect ? tile.iconRect.x : Math.round((tile.width - tile.fallbackIconSize) / 2)
        y: tile.iconRect ? tile.iconRect.y
                         : (tile.labelLines.length > 0
                            ? Math.round((tile.height - 34 - tile.fallbackIconSize) / 2)
                            : Math.round((tile.height - tile.fallbackIconSize) / 2))
        width: tile.iconRect ? tile.iconRect.w : tile.fallbackIconSize
        height: tile.iconRect ? tile.iconRect.h : tile.fallbackIconSize
    }

    BaseText {
        x: Metrics.labelX
        baselineY: (tile.twoLines ? Metrics.labelBaseline - Metrics.labelLineGap : Metrics.labelBaseline) - (hasCjk ? Metrics.cjkBaselineShift : 0)
        text: tile.labelLines.length > 0 ? tile.labelLines[0] : ""
        pixelSize: Metrics.labelSize
        family: Metrics.fontFamily
        letterSpacing: hasCjk ? Metrics.cjkLetterSpacing : 0
        maxWidth: tile.width - 2 * Metrics.labelX
        elide: tile.twoLines ? Text.ElideNone : Text.ElideRight
    }

    BaseText {
        x: Metrics.labelX
        baselineY: Metrics.labelBaseline - (hasCjk ? Metrics.cjkBaselineShift : 0)
        text: tile.twoLines ? tile.labelLines[1] : ""
        pixelSize: Metrics.labelSize
        family: Metrics.fontFamily
        letterSpacing: hasCjk ? Metrics.cjkLetterSpacing : 0
    }

    // Reveal border: 1 px, brightest on the hovered tile and fading with
    // distance so neighbouring tiles pick up the pointer light.
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: tile.hovered
                      ? Qt.rgba(1, 1, 1, 0.38)
                      : (tile.pointerInside ? Qt.rgba(1, 1, 1, 0.02 + 0.20 * tile.reveal)
                                            : "transparent")
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        onTapped: tile.activated(tile.tileData)
    }
}
