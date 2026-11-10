// Windows 10 style start sidebar: hamburger, two sections, user and power.
import QtQuick
import QtQuick.Effects
import "metrics.js" as Metrics

Item {
    id: root
    property bool expanded: false
    property bool bottomLabels: false
    property bool hovered: false
    property bool separators: false
    property string selected: "tiles"
    property string wallpaperUrl: ""
    property string userName: ""
    property string avatar: ""
    property var ui: null
    property bool compositorBlur: false
    property real blurFactor: 96
    property color panelColor: "#363532"
    property real panelAlpha: 0.87
    signal sectionActivated(string id)
    signal powerActivated()

    readonly property bool labelsVisible: expanded
    readonly property bool userLabels: expanded || bottomLabels
    width: expanded ? Metrics.sidebarExpandedWidth : Metrics.sidebarCollapsedWidth
    height: parent ? parent.height : 1380
    clip: true

    Item {
        anchors.fill: parent
        visible: expanded || bottomLabels
        Rectangle {
            anchors.fill: parent
            color: root.panelColor
            opacity: root.compositorBlur ? root.panelAlpha : 1.0
        }
        Image {
            x: 0; y: 0
            width: 2560; height: 1380
            visible: !root.compositorBlur && root.wallpaperUrl !== ""
            source: root.wallpaperUrl
            sourceSize: Qt.size(Math.max(1, Math.round(2560 / root.blurFactor)),
                                Math.max(1, Math.round(1380 / root.blurFactor)))
            fillMode: Image.Stretch
            smooth: true
            opacity: 1 - root.panelAlpha
        }
    }

    Image {
        x: 26; y: 33
        width: 24; height: 17
        source: Qt.resolvedUrl("../assets/ui/hamburger.png")
        smooth: true
        MouseArea {
            anchors.fill: parent
            onClicked: root.sectionActivated("toggle")
        }
    }

    BaseText {
        visible: root.labelsVisible
        x: 73
        baselineY: 50
        text: "开始"
        family: Metrics.fontFamily
        pixelSize: Metrics.sidebarTitleSize
    }

    Repeater {
        model: [
            { id: "tiles", label: "已固定的磁贴", icon: "grid" },
            { id: "apps", label: "所有应用", icon: "list" }
        ]
        delegate: Item {
            required property var modelData
            required property int index
            y: Metrics.sidebarItemsTop + index * Metrics.sidebarItemHeight
            width: root.width
            height: Metrics.sidebarItemHeight

            readonly property bool isSelected: root.selected === modelData.id
            readonly property string glyphFile: {
                const selected = root.selected === modelData.id
                if (modelData.id === "apps")
                    return Qt.resolvedUrl("../assets/ui/" + (selected ? "list-selected" : "list") + ".png")
                return Qt.resolvedUrl("../assets/ui/" + (selected ? "grid" : "grid-normal") + ".png")
            }

            Rectangle {
                visible: root.expanded && parent.isSelected && root.hovered
                anchors.fill: parent
                color: "#FFFFFF"
                opacity: 0.09
            }

            Rectangle {
                visible: parent.isSelected
                x: 0; y: 0
                width: Metrics.sidebarAccentWidth
                height: parent.height
                color: Metrics.sidebarAccentColor
            }

            Image {
                x: 27; y: 25
                width: 22; height: 22
                source: parent.glyphFile
                smooth: true
            }

            BaseText {
                visible: root.labelsVisible
                x: 73
                baselineY: index === 0 ? 42.5 : 43.5
                text: modelData.label
                color: parent.isSelected ? Metrics.sidebarSelectedColor : "#FFFFFF"
                family: Metrics.fontFamily
                pixelSize: Metrics.sidebarItemSize
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.sectionActivated(modelData.id)
            }
        }
    }

    Rectangle {
        visible: root.separators
        x: 0; y: 1236; width: root.width; height: 2
        color: "#434445"
    }

    Rectangle {
        visible: root.separators
        x: 0; y: 1306; width: root.width; height: 2
        color: "#3C3D3E"
    }

    Avatar {
        x: 23; y: 1257
        size: 30
        source: root.avatar
    }

    BaseText {
        visible: root.userLabels && root.userName !== ""
        x: 74
        baselineY: 1280
        text: root.userName
        family: Metrics.fontFamily
        pixelSize: 21
    }

    Image {
        x: 26; y: 1332
        width: 24; height: 24
        source: Qt.resolvedUrl("../assets/ui/power.png")
        smooth: true
        MouseArea {
            anchors.fill: parent
            onClicked: root.powerActivated()
        }
    }

    BaseText {
        visible: root.userLabels
        x: 72
        baselineY: 1351
        text: "电源"
        family: Metrics.fontFamily
        pixelSize: Metrics.sidebarItemSize
    }
}
