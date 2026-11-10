// Renders an application or menu icon from either a theme name or a file path.
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root
    property string source: ""
    property int size: 48

    width: size
    height: size

    readonly property bool isFile: source.indexOf("/") === 0
                                    || source.indexOf("file:") === 0
                                    || source.indexOf("image:") === 0

    Image {
        anchors.fill: parent
        visible: root.source !== "" && root.isFile
        source: root.isFile ? root.source : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Kirigami.Icon {
        anchors.fill: parent
        visible: root.source !== "" && !root.isFile
        source: root.isFile ? "" : root.source
        smooth: true
    }
}
