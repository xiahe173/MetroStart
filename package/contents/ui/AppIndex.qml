// Enumerates the applications menu using the Plasma "apps" data engine, the
// same source the application launcher uses.
import QtQuick
import Qt.labs.folderlistmodel
import org.kde.plasma.plasma5support as P5Support
import "Paths.js" as Paths

Item {
    id: appIndex

    property string homeDir: ""
    property var apps: []
    property bool ready: false

    readonly property var searchDirs: {
        var home = homeDir
        return Paths.applicationsDirs()
    }

    property var seen: ({})
    property var entries: ({})
    property int expected: 0
    property var pendingNames: []
    property bool loading: false

    function collect(fileName) {
        if (!fileName || !fileName.endsWith(".desktop"))
            return
        if (seen[fileName])
            return
        seen[fileName] = true
        pendingNames.push(fileName)
        schedule()
    }

    function schedule() {
        if (loading || pendingNames.length === 0)
            return
        loading = true
        connectTimer.restart()
    }

    function flush() {
        if (pendingNames.length === 0) {
            loading = false
            return
        }
        var names = pendingNames
        pendingNames = []
        expected += names.length
        source.connectedSources = source.connectedSources.concat(names)
        loading = false
    }

    function publish() {
        var list = []
        for (var k in entries) {
            var e = entries[k]
            if (e.display === false || e.isApp === false)
                continue
            if (!e.name)
                continue
            list.push(e)
        }
        list.sort(function (a, b) { return a.name.localeCompare(b.name) })
        apps = list
        ready = true
    }

    Timer {
        id: connectTimer
        interval: 40
        repeat: false
        onTriggered: appIndex.flush()
    }

    Timer {
        id: publishTimer
        interval: 250
        repeat: false
        onTriggered: appIndex.publish()
    }

    Repeater {
        model: 5

        delegate: Item {
            id: dirDelegate
            required property int index
            readonly property string dir: appIndex.searchDirs[index] !== undefined
                                           ? appIndex.searchDirs[index] : ""

            FolderListModel {
                folder: dirDelegate.dir !== "" ? "file://" + dirDelegate.dir : ""
                nameFilters: ["*.desktop"]
                showDirs: false
                onCountChanged: {
                    for (var i = 0; i < count; ++i)
                        appIndex.collect(get(i, "fileName"))
                }
            }
        }
    }

    P5Support.DataSource {
        id: source
        engine: "apps"
        onNewData: (sourceName, data) => {
            var entry = {
                id: data.menuId || sourceName,
                name: data.name || "",
                icon: data.iconName || "",
                path: data.entryPath || "",
                display: data.display,
                isApp: data.isApp
            }
            appIndex.entries[sourceName] = entry
            publishTimer.restart()
        }
    }

    onHomeDirChanged: seen = ({})
}
