// The pinned tiles: groups of tiles, optionally with editable group titles.
import QtQuick
import "metrics.js" as Metrics

Item {
    id: root
    property var groups: []
    property bool titlesVisible: false
    property real pointerX: -1
    property real pointerY: -1
    property bool pointerInside: false
    signal tileActivated(var entry)

    Repeater {
        model: root.groups
        delegate: Item {
            required property var modelData
            Repeater {
                model: modelData.tiles
                delegate: Tile {
                    required property var modelData
                    tileData: modelData
                    pointerX: root.pointerX
                    pointerY: root.pointerY
                    pointerInside: root.pointerInside
                    onActivated: (entry) => root.tileActivated(entry)
                }
            }
        }
    }

    Repeater {
        model: root.groups
        delegate: BaseText {
            required property var modelData
            visible: root.titlesVisible && modelData.title !== ""
            x: modelData.x
            baselineY: modelData.y + Metrics.groupTitleOffsetY
            text: modelData.title
            family: Metrics.fontFamily
            pixelSize: Metrics.groupTitleSize
        }
    }
}
