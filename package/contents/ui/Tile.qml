// A single tile: translucent fill, icon and up to two label lines.
import QtQuick
import "metrics.js" as Metrics

Item {
    id: tile
    property var tileData: null
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

    Rectangle {
        anchors.fill: parent
        color: Metrics.tileFill
        opacity: Metrics.tileFillOpacity
    }

    readonly property var iconRect: (tileData && tileData.iconRect) ? tileData.iconRect : null

    readonly property int fallbackIconSize: Math.round(Math.min(width, height) * (labelLines.length > 0 ? 0.42 : 0.5))

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

    MouseArea {
        anchors.fill: parent
        enabled: !!tile.tileData && (!!tile.tileData.exec || !!tile.tileData.desktopId)
        onClicked: tile.activated(tile.tileData)
    }
}
