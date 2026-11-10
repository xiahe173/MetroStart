// Paths used by the applet. HOME is resolved at runtime (see Runtime.qml);
// everything machine specific lives outside the package.
.pragma library

var homeDir = ""
var configRelPath = "/.config/metrostart/layout.json"

function setHome(dir) {
    homeDir = dir || ""
}

function configPath() {
    return homeDir !== "" ? homeDir + configRelPath : ""
}

function applicationsDirs() {
    var dirs = []
    if (homeDir !== "")
        dirs.push(homeDir + "/.local/share/applications")
    dirs.push("/usr/share/applications")
    dirs.push("/usr/local/share/applications")
    if (homeDir !== "")
        dirs.push(homeDir + "/.local/share/flatpak/exports/share/applications")
    dirs.push("/var/lib/flatpak/exports/share/applications")
    return dirs
}
