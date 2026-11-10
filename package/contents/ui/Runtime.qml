// The applet's live data: home directory, layout file, applications, user.
import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.coreaddons as KCoreAddons
import "Paths.js" as Paths
import "Layout.js" as Layout

Item {
    id: runtime

    property string homeDir: ""
    property var config: null
    property bool configLoaded: false
    property string configPath: ""
    property var apps: appIndex.apps
    property bool ready: appIndex.ready

    readonly property string userName: (kuser.fullName !== undefined && kuser.fullName !== "")
                                        ? kuser.fullName
                                        : (kuser.loginName !== undefined ? kuser.loginName : "")
    readonly property string fullName: kuser.fullName !== undefined ? kuser.fullName : ""
    readonly property url avatarUrl: kuser.faceIconUrl !== undefined ? kuser.faceIconUrl : ""

    KCoreAddons.KUser {
        id: kuser
    }

    AppIndex {
        id: appIndex
        homeDir: runtime.homeDir
    }

    // HOME is needed before the applications directories can be listed.
    P5Support.DataSource {
        id: shell
        engine: "executable"
        onNewData: (sourceName, data) => {
            shell.disconnectSource(sourceName)
        }
    }

    function run(command, onDone) {
        const cb = function (sourceName, data) {
            shell.newData.disconnect(cb)
            if (onDone)
                onDone(data)
        }
        shell.newData.connect(cb)
        shell.connectSource(command)
    }

    function loadConfig() {
        const path = Paths.configPath()
        runtime.configPath = path
        if (path === "")
            return
        run("cat \"" + path + "\"", function (data) {
            if (data && data["exit code"] === 0 && data.stdout) {
                try {
                    runtime.config = JSON.parse(data.stdout)
                } catch (e) {
                    console.warn("MetroStart: cannot parse " + path + ": " + e)
                }
            }
            runtime.configLoaded = true
        })
    }

    function launch(entry) {
        const target = entry && entry.path ? entry.path : (entry && entry.desktopId ? entry.desktopId : "")
        if (target === "")
            return
        run("gio launch \"" + target + "\" 2>/dev/null || kioclient5 exec \"" + target + "\"")
    }

    function powerAction(action) {
        switch (action) {
        case "suspend": run("systemctl suspend"); break
        case "poweroff": run("systemctl poweroff"); break
        case "reboot": run("systemctl reboot"); break
        case "logout": run("qdbus6 org.kde.ksmserver /KSMServer logout 0 0 0 2>/dev/null || qdbus org.kde.ksmserver /KSMServer logout 0 0 0"); break
        }
    }

    Component.onCompleted: {
        run("printf %s \"$HOME\"", function (data) {
            runtime.homeDir = (data && data.stdout) ? data.stdout.trim() : ""
            Paths.setHome(runtime.homeDir)
            runtime.loadConfig()
        })
    }
}
