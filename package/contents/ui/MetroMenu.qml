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
    property string flyout: ""             // "" | "power" | "user"
    readonly property bool expandedSidebar: sidebarExpanded
    signal backgroundClicked()
    signal closeRequested()

    readonly property var ctx: context !== null ? context : runtimeContext
    readonly property var layout: Layout.resolve(ctx.config, ctx.apps || [], { width: width, height: height })
    readonly property var sections: (ctx.appLayout && ctx.appLayout.sections)
                                     ? ctx.appLayout.sections
                                     : Layout.appSections(ctx.apps || [])

    property bool runtimeActive: context === null

    Runtime {
        id: runtime
        visible: false
    }

    readonly property var runtimeContext: ({
        apps: runtime.apps,
        config: runtime.config,
        appLayout: null,
        wallpaper: "",
        avatar: runtime.avatarUrl,
        userName: runtime.userName,
        launch: function (entry) { runtime.launch(entry) }
    })

    clip: true

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

    MouseArea {
        anchors.fill: parent
        onClicked: root.backgroundClicked()
    }

    TilesView {
        anchors.fill: parent
        visible: root.view === "tiles"
        groups: root.layout.groups
        titlesVisible: root.groupTitles
        onTileActivated: (entry) => {
            if (root.ctx.launch)
                root.ctx.launch(entry)
            root.closeRequested()
        }
    }

    AppListView {
        anchors.fill: parent
        visible: root.view === "apps"
        sections: root.sections
        onEntryActivated: (entry) => {
            if (root.ctx.launch)
                root.ctx.launch(entry)
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
        wallpaperUrl: root.ctx.wallpaper || ""
        compositorBlur: root.runtimeActive
        userName: root.ctx.userName || ""
        avatar: root.ctx.avatar || ""
        onSectionActivated: (id) => {
            if (id === "toggle")
                root.sidebarExpanded = !root.sidebarExpanded
            else
                root.view = id
        }
        onPowerActivated: root.flyout = (root.flyout === "power" ? "" : "power")
    }

    Flyout {
        kind: root.flyout
        userName: root.ctx.userName || ""
        avatar: root.ctx.avatar || ""
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
