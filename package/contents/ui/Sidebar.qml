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
    property real pointerX: -1
    property real pointerY: -1
    property bool pointerInside: false
    property string debugHoverControl: ""
    property bool hoverInjected: false
    property string userName: ""
    property string avatar: ""
    property var ui: null
    property real blurFactor: 48
    property color panelColor: "#363532"
    property real panelAlpha: 0.84
    // Distance within which a control border lights up without being hovered.
    readonly property int nearRadius: 140

    // Geometry of every sidebar button. All buttons share the same hover look:
    // a fill, an interior glow and a border glow that only lights the part of
    // the outline close to the pointer.
    readonly property var buttons: [
        { id: "header", y: 0, h: Metrics.sidebarHeaderHeight },
        { id: "tiles",  y: Metrics.sidebarItemsTop, h: Metrics.sidebarItemHeight },
        { id: "apps",   y: Metrics.sidebarItemsTop + Metrics.sidebarItemHeight, h: Metrics.sidebarItemHeight },
        { id: "user",   y: Metrics.sidebarUserY, h: Metrics.sidebarUserHeight },
        { id: "power",  y: Metrics.sidebarPowerY, h: Metrics.sidebarPowerHeight }
    ]
    property string hoveredControl: ""

    function isHovered(id) {
        if (debugHoverControl !== "")
            return debugHoverControl === id
        return hoveredControl === id
    }

    function enterControl(id) {
        if (!hoverInjected)
            hoveredControl = id
    }

    function leaveControl(id) {
        if (!hoverInjected && hoveredControl === id)
            hoveredControl = ""
    }

    // Peak alpha of a horizontal boundary line at `y`: bright when either
    // adjacent button is hovered, faint while the pointer is close to it.
    readonly property var boundaries: {
        var list = []
        for (var i = 0; i < buttons.length; ++i)
            list.push(buttons[i].y)
        list.push(buttons[buttons.length - 1].y + buttons[buttons.length - 1].h)
        return list
    }

    function linePeak(y) {
        for (var i = 0; i < buttons.length; ++i) {
            const b = buttons[i]
            if ((b.y === y || b.y + b.h === y) && isHovered(b.id))
                return 0.42
        }
        if (isNear(0, y - 1, width, 2))
            return 0.16
        return 0
    }

    function verticalPeak() {
        if (hoveredControl !== "" || debugHoverControl !== "")
            return 0.42
        return pointerInside ? 0.16 : 0
    }

    // True when the pointer is close enough to a control for its border to
    // light up even without hovering it.
    function isNear(x, y, w, h) {
        if (!pointerInside)
            return false
        const dx = Math.max(x - pointerX, 0, pointerX - (x + w))
        const dy = Math.max(y - pointerY, 0, pointerY - (y + h))
        return Math.hypot(dx, dy) < nearRadius
    }

    signal sectionActivated(string id)
    signal powerActivated()
    signal userActivated()

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
        }
        Image {
            x: 0; y: 0
            width: 2560; height: 1440
            visible: root.wallpaperUrl !== ""
            source: root.wallpaperUrl
            sourceSize: Qt.size(Math.max(1, Math.round(2560 / root.blurFactor)),
                                Math.max(1, Math.round(1440 / root.blurFactor)))
            fillMode: Image.Stretch
            smooth: true
            opacity: 1 - root.panelAlpha
        }
    }

    Item {
        id: headerButton
        x: 0
        y: 0
        width: root.width
        height: Metrics.sidebarHeaderHeight

        Rectangle {
            anchors.fill: parent
            color: "#FFFFFF"
            opacity: root.isHovered("header") ? 0.13 : 0
        }
        RevealGlow {
            anchors.fill: parent
            anchors.margins: 2
            radius: 320
            localX: root.pointerX - headerButton.x
            localY: root.pointerY - headerButton.y
            strength: root.isHovered("header") ? 0.04 : 0
        }

        Image {
            x: 26; y: 33
            width: 24; height: 17
            source: Qt.resolvedUrl("../assets/ui/hamburger.png")
            smooth: true
        }
        BaseText {
            visible: root.labelsVisible
            x: 73
            baselineY: 50
            text: "开始"
            family: Metrics.fontFamily
            pixelSize: Metrics.sidebarTitleSize
        }

        HoverHandler {
            enabled: !root.hoverInjected
            onHoveredChanged: hovered ? root.enterControl("header") : root.leaveControl("header")
        }
        TapHandler { onTapped: root.sectionActivated("toggle") }
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
                color: (parent.isSelected && root.isHovered(modelData.id))
                       ? "#6C91B5" : "#4A78A4"
            }

            Image {
                x: 27; y: 25
                width: 22; height: 22
                source: parent.glyphFile
                smooth: true
            }

            Rectangle {
                anchors.fill: parent
                color: "#FFFFFF"
                opacity: root.isHovered(modelData.id) ? 0.13 : 0
            }
            RevealGlow {
                anchors.fill: parent
                anchors.margins: 2
                radius: 240
                localX: root.pointerX - parent.x
                localY: root.pointerY - parent.y
                strength: root.isHovered(modelData.id) ? 0.04 : 0
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

            HoverHandler {
                enabled: !root.hoverInjected
                onHoveredChanged: hovered ? root.enterControl(modelData.id) : root.leaveControl(modelData.id)
            }
            TapHandler { onTapped: root.sectionActivated(modelData.id) }
        }
    }

    Rectangle {
        visible: root.separators
        x: 0; y: Metrics.sidebarUserY; width: root.width; height: 2
        color: "#434445"
    }

    Rectangle {
        visible: root.separators
        x: 0; y: Metrics.sidebarPowerY; width: root.width; height: 2
        color: "#3C3D3E"
    }

    Item {
        id: userButton
        x: 0
        y: Metrics.sidebarUserY
        width: root.width
        height: Metrics.sidebarUserHeight

        Rectangle {
            anchors.fill: parent
            color: "#FFFFFF"
            opacity: root.isHovered("user") ? 0.13 : 0
        }
        RevealGlow {
            anchors.fill: parent
            anchors.margins: 2
            radius: 240
            localX: root.pointerX - userButton.x
            localY: root.pointerY - userButton.y
            strength: root.isHovered("user") ? 0.04 : 0
        }

        Avatar {
            x: 23; y: 21
            size: 30
            source: root.avatar
        }

        BaseText {
            visible: root.userLabels && root.userName !== ""
            x: 74
            baselineY: 44
            text: root.userName
            family: Metrics.fontFamily
            pixelSize: 21
        }

        HoverHandler {
            enabled: !root.hoverInjected
            onHoveredChanged: hovered ? root.enterControl("user") : root.leaveControl("user")
        }
        TapHandler { onTapped: root.userActivated() }
    }

    Item {
        id: powerButton
        x: 0
        y: Metrics.sidebarPowerY
        width: root.width
        height: Metrics.sidebarPowerHeight

        Rectangle {
            anchors.fill: parent
            color: "#FFFFFF"
            opacity: root.isHovered("power") ? 0.13 : 0
        }
        RevealGlow {
            anchors.fill: parent
            anchors.margins: 2
            radius: 240
            localX: root.pointerX - powerButton.x
            localY: root.pointerY - powerButton.y
            strength: root.isHovered("power") ? 0.04 : 0
        }

        Image {
            x: 26; y: 26
            width: 24; height: 24
            source: Qt.resolvedUrl("../assets/ui/power.png")
            smooth: true
        }

        BaseText {
            visible: root.userLabels
            x: 72
            baselineY: 45
            text: "电源"
            family: Metrics.fontFamily
            pixelSize: Metrics.sidebarItemSize
        }

        HoverHandler {
            enabled: !root.hoverInjected
            onHoveredChanged: hovered ? root.enterControl("power") : root.leaveControl("power")
        }
        TapHandler { onTapped: root.powerActivated() }
    }

    // Single border layer: every boundary is drawn once, so shared edges are
    // exactly as thick as the outer ones.
    Item {
        anchors.fill: parent

        RevealEdge {
            x: 0; y: 0
            width: 3; height: parent.height
            vertical: true
            start: 0
            length: parent.height
            edgePos: 0
            pointerX: root.pointerX
            pointerY: root.pointerY
            peak: root.verticalPeak()
            radius: 85
            visible: peak > 0
        }
        RevealEdge {
            x: parent.width - 3; y: 0
            width: 3; height: parent.height
            vertical: true
            start: 0
            length: parent.height
            edgePos: parent.width
            pointerX: root.pointerX
            pointerY: root.pointerY
            peak: root.verticalPeak()
            radius: 85
            visible: peak > 0
        }

        Repeater {
            model: root.boundaries
            delegate: RevealEdge {
                required property var modelData
                x: 3; y: modelData
                width: root.width - 6; height: 3
                vertical: false
                start: 3
                length: root.width - 6
                edgePos: modelData
                pointerX: root.pointerX
                pointerY: root.pointerY
                peak: root.linePeak(modelData)
                radius: 85
                visible: peak > 0
            }
        }
    }
}
