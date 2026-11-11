// Plasma applet entry point. The panel button opens a full-screen overlay
// window (layer-shell) so the menu has no dialog padding and can cover the
// whole work area.
import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.layershell as LayerShell

PlasmoidItem {
    id: root

    implicitWidth: 32
    implicitHeight: 32
    activationTogglesExpanded: false

    // Plasma needs a full representation to instantiate the compact one in the
    // panel; the menu itself is the overlay window below.
    fullRepresentation: Item {
        implicitWidth: 32
        implicitHeight: 32
    }

    function openMenu() {
        overlay.show()
        overlay.requestActivate()
    }

    function closeMenu() {
        overlay.hide()
    }

    onExpandedChanged: {
        if (expanded) {
            openMenu()
            expanded = false
        }
    }

    compactRepresentation: Item {
        implicitWidth: 32
        implicitHeight: 32
        width: 32
        height: 32

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: mouse.containsMouse ? "#30FFFFFF" : "transparent"
        }

        Image {
            anchors.centerIn: parent
            width: 22
            height: 22
            source: Qt.resolvedUrl("../assets/ui/grid.png")
            smooth: true
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: overlay.visible ? closeMenu() : openMenu()
        }
    }

    Window {
        id: overlay
        objectName: "metroOverlay"
        visible: false
        flags: Qt.FramelessWindowHint
        color: "#000000"
        title: "MetroStart"

        readonly property int screenWidth: Screen.width > 0 ? Screen.width : 2560
        readonly property int screenHeight: Screen.height > 0 ? Screen.height : 1440
        // The reference layout assumes a 60 px taskbar at 2560 px wide.
        // Screen reports logical pixels, so scale the panel with the menu.
        readonly property int panelHeight: Math.round(60 * screenWidth / 2560)
        // Set once the window has been mapped and activated; only then does
        // losing focus close the menu.
        property bool armed: false

        width: screenWidth
        height: Math.max(1, screenHeight - panelHeight)
        x: 0
        y: 0

        // Panel level, not overlay: panel context menus and other overlay-layer
        // surfaces are allowed to stay above the Start menu.
        LayerShell.Window.layer: LayerShell.Window.LayerTop
        LayerShell.Window.anchors: LayerShell.Window.AnchorTop
                                    | LayerShell.Window.AnchorLeft
                                    | LayerShell.Window.AnchorRight
        LayerShell.Window.exclusionZone: -1
        LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand
        LayerShell.Window.activateOnShow: true
        LayerShell.Window.scope: "metrostart"

        MetroMenu {
            id: menu
            width: 2560
            height: 1380
            transform: Scale {
                xScale: overlay.width / 2560
                yScale: overlay.height / 1380
            }
            onCloseRequested: root.closeMenu()
        }

        Shortcut {
            sequence: "Escape"
            enabled: overlay.visible
            onActivated: root.closeMenu()
        }

        // Like a popup: any interaction outside the window hides the menu.
        // A short grace period avoids closing while the window is still being
        // mapped and activated.
        Timer {
            id: armTimer
            interval: 250
            onTriggered: overlay.armed = true
        }
        onActiveChanged: {
            if (!active && armed)
                root.closeMenu()
        }
        onVisibleChanged: {
            if (visible) {
                armed = false
                armTimer.restart()
                menu.reloadWallpaper()
                requestActivate()
            } else {
                armTimer.stop()
                armed = false
            }
        }
    }
}
