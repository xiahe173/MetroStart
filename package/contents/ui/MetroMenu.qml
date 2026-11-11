// MetroStart menu surface: backdrop, tiles or app list, sidebar and flyouts.
import QtQuick
import "metrics.js" as Metrics
import "Layout.js" as Layout

Item {
    id: root

    // Injected by the preview harness; when null the applet uses its own data.
    property var context: null

    property string view: "tiles"          // "tiles" | "apps"
    property bool sidebarExpanded: false
    property bool sidebarBottomLabels: false
    property bool sidebarHover: false
    property bool bottomSeparators: false
    property bool groupTitles: false
    property bool renaming: false
    property real pointerX: -1
    property real pointerY: -1
    property bool pointerInside: false
    // Hooks used by the offscreen render harness to place the pointer (and the
    // hovered control) at a fixed position. They are off in the applet itself.
    property bool debugPointerActive: false
    property bool debugPointerInside: true
    property real debugPointerX: 0
    property real debugPointerY: 0
    property int debugHoverTile: -1
    property string debugHoverControl: ""

    readonly property real effectivePointerX: debugPointerActive ? debugPointerX : pointerX
    readonly property real effectivePointerY: debugPointerActive ? debugPointerY : pointerY
    readonly property bool effectivePointerInside: debugPointerActive ? debugPointerInside : pointerInside
    property string flyout: ""             // "" | "power" | "user"
    readonly property bool expandedSidebar: sidebarExpanded
    signal closeRequested()

    function reloadWallpaper() {
        if (runtimeActive)
            runtime.loadWallpaper()
    }

    function launchEntry(entry) {
        if (context !== null) {
            if (context.launch)
                context.launch(entry)
        } else {
            runtime.launch(entry)
        }
    }

    readonly property var appsData: context !== null ? context.apps : runtime.apps
    readonly property var configData: context !== null ? context.config : runtime.config
    readonly property var appLayoutData: context !== null ? context.appLayout : null
    readonly property string wallpaperData: context !== null
                                             ? (context.wallpaper || "")
                                             : runtime.wallpaperUrl
    readonly property string userNameData: context !== null
                                            ? (context.userName || "")
                                            : runtime.userName
    readonly property string avatarData: context !== null
                                         ? (context.avatar || "")
                                         : runtime.avatarUrl

    readonly property var layout: Layout.resolve(configData, appsData || [], { width: width, height: height })
    readonly property var sections: (appLayoutData && appLayoutData.sections)
                                     ? appLayoutData.sections
                                     : Layout.appSections(appsData || [])

    property bool runtimeActive: context === null

    Runtime {
        id: runtime
        visible: false
    }

    clip: true

    HoverHandler {
        id: menuHover
        enabled: context === null
        onPointChanged: {
            if (hovered) {
                root.pointerX = point.position.x
                root.pointerY = point.position.y
            }
        }
        onHoveredChanged: root.pointerInside = hovered
    }
    // The menu paints the desktop wallpaper itself, aligned 1:1 with the
    // screen (2560x1440 design space), so no compositor backdrop is needed.
    Image {
        id: wallpaperImage
        x: 0
        y: 0
        width: 2560
        height: 1440
        source: root.wallpaperData || ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: source !== ""
    }

    // 80 % backdrop: the reference composite is exactly 0.2 * wallpaper + 34.
    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
        opacity: 0.4
    }
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6666667
    }

    TilesView {
        anchors.fill: parent
        visible: root.view === "tiles"
        groups: root.layout.groups
        titlesVisible: root.groupTitles
        pointerX: root.effectivePointerX
        pointerY: root.effectivePointerY
        pointerInside: root.effectivePointerInside
        debugHoverTile: root.debugHoverTile
        hoverInjected: root.debugPointerActive
        onTileActivated: (entry) => {
            root.launchEntry(entry)
            root.closeRequested()
        }
    }

    AppListView {
        anchors.fill: parent
        visible: root.view === "apps"
        sections: root.sections
        onEntryActivated: (entry) => {
            root.launchEntry(entry)
            root.closeRequested()
        }
    }

    Sidebar {
        id: sidebar
        expanded: root.sidebarExpanded
        bottomLabels: root.sidebarBottomLabels
        hovered: root.sidebarHover
        separators: root.bottomSeparators
        selected: root.view === "apps" ? "apps" : "tiles"
        wallpaperUrl: root.wallpaperData || ""
        pointerX: root.effectivePointerX
        pointerY: root.effectivePointerY
        pointerInside: root.effectivePointerInside
        debugHoverControl: root.debugHoverControl
        hoverInjected: root.debugPointerActive
        userName: root.userNameData || ""
        avatar: root.avatarData || ""
        onSectionActivated: (id) => {
            if (id === "toggle")
                root.sidebarExpanded = !root.sidebarExpanded
            else
                root.view = id
        }
        onPowerActivated: root.flyout = (root.flyout === "power" ? "" : "power")
        onUserActivated: root.flyout = (root.flyout === "user" ? "" : "user")
    }

    Flyout {
        kind: root.flyout
        userName: root.userNameData || ""
        avatar: root.avatarData || ""
        onPowerAction: (action) => {
            if (root.runtimeActive)
                runtime.powerAction(action)
            root.closeRequested()
        }
    }

    // Group rename overlay
    Item {
        visible: root.renaming
        x: 995
        y: 837
        width: 569
        height: 84

        Rectangle { anchors.fill: parent; color: "#4A78A4" }
        Rectangle { x: 12; y: 21; width: 483; height: 41; color: "#FFFFFF" }
        Rectangle { x: 21; y: 27; width: 2; height: 30; color: "#000000" }
        Rectangle { x: 522; y: 39; width: 23; height: 2; color: "#FFFFFF" }
        Rectangle { x: 522; y: 43; width: 23; height: 2; color: "#FFFFFF" }
    }
}
