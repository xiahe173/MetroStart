// Power and user flyouts anchored at the bottom left of the sidebar.
import QtQuick
import "metrics.js" as Metrics

Item {
    id: root
    property string kind: ""            // "power" | "user"
    property string userName: ""
    property string avatar: ""
    signal powerAction(string action)

    readonly property bool isPower: kind === "power"
    visible: kind !== ""
    width: 386
    height: 1380

    Item {
        x: 0
        y: root.isPower ? 1137 : 993
        width: root.isPower ? 386 : 383
        height: root.isPower ? 165 : 237

        Rectangle {
            anchors.fill: parent
            color: Metrics.menuPanelColor
        }

        Repeater {
            model: root.isPower
                ? [{ icon: "hibernate", label: "休眠", action: "suspend" },
                   { icon: "shutdown", label: "关机", action: "poweroff" },
                   { icon: "restart", label: "重启", action: "reboot" }]
                : [{ icon: "account", label: "更改帐户设置", action: "" },
                   { icon: "lock", label: "锁定", action: "" },
                   { icon: "logout", label: "注销", action: "logout" }]
            delegate: Item {
                required property var modelData
                required property int index
                y: index * 49
                width: root.width
                height: 49

                Image {
                    x: 23; y: 21
                    width: 26; height: 26
                    source: Qt.resolvedUrl("../assets/ui/" + modelData.icon + ".png")
                    smooth: true
                }
                BaseText {
                    x: 66
                    baselineY: 39
                    text: modelData.label
                    family: Metrics.fontFamily
                    pixelSize: 18
                    letterSpacing: hasCjk ? 1 : 0
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (modelData.action !== "") root.powerAction(modelData.action)
                }
            }
        }

        Rectangle {
            visible: !root.isPower
            x: 22; y: 163
            width: 345; height: 2
            color: "#7A7A7B"
        }

        Avatar {
            visible: !root.isPower
            x: 23; y: 175
            size: 50
            source: root.avatar
        }

        BaseText {
            visible: !root.isPower && root.userName !== ""
            x: 84
            baselineY: 207
            text: root.userName
            family: Metrics.fontFamily
            pixelSize: 17
        }
    }
}
