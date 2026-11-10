// "All applications": three columns, letter sections, scrolling.
import QtQuick
import "metrics.js" as Metrics

Item {
    id: root
    property var sections: []
    signal entryActivated(var entry)

    readonly property real contentHeight: {
        var h = 0
        for (var i = 0; i < sections.length; ++i) {
            var n = sections[i].entries.length
            var rows = Math.max(1, Math.ceil(n / 3))
            h = Math.max(h, sections[i].y + rows * 66)
        }
        return h + Metrics.appSectionGap
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(root.contentHeight, root.height)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Repeater {
            model: root.sections
            delegate: Item {
                required property var modelData
                y: modelData.y

                BaseText {
                    x: Metrics.appLetterX
                    baselineY: 32
                    text: modelData.letter
                    family: Metrics.fontFamily
                    pixelSize: Metrics.appLetterSize
                }

                Repeater {
                    model: modelData.entries
                    delegate: Item {
                        required property var modelData

                        readonly property int column: modelData.col !== undefined ? modelData.col : 0
                        x: Metrics.appColumns[column]
                        y: (modelData.row !== undefined ? modelData.row : 0) * 66
                        width: 366
                        height: Metrics.appIconSize

                        AppIcon {
                            x: 0
                            y: 0
                            size: Metrics.appIconSize
                            source: modelData.icon || ""
                        }

                        BaseText {
                            x: Metrics.appNameOffsetX
                            baselineY: 32
                            text: modelData.name
                            family: Metrics.fontFamily
                            pixelSize: Metrics.appNameSize
                            letterSpacing: hasCjk ? 1 : 0
                            maxWidth: 290
                            elide: Text.ElideRight
                        }

                        Image {
                            visible: !!modelData.folder
                            x: 317; y: 15
                            width: 15; height: 8
                            source: Qt.resolvedUrl("../assets/ui/chevron.png")
                            smooth: true
                        }

                        TapHandler {
                            onTapped: root.entryActivated(modelData)
                        }
                    }
                }
            }
        }
    }

    // thin scrollbar on the right edge
    Rectangle {
        visible: flick.contentHeight > flick.height
        x: parent.width - 6
        y: Math.max(0, Math.min(flick.height - height, flick.contentY / Math.max(1, flick.contentHeight) * flick.height))
        width: 3
        height: Math.max(40, flick.height * flick.height / Math.max(1, flick.contentHeight))
        color: "#5A5A5A"
        opacity: 0.7
    }
}
