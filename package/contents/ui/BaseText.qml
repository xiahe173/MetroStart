// Text positioned by its baseline instead of its (font dependent) top edge.
import QtQuick

Item {
    id: root
    property string text: ""
    property int pixelSize: 17
    property string family: "Noto Sans"
    property color color: "#FFFFFF"
    property real baselineY: 0
    property real letterSpacing: 0
    property real maxWidth: 0
    property int elide: Text.ElideNone
    visible: text !== ""
    width: maxWidth > 0 ? Math.min(label.implicitWidth, maxWidth) : label.implicitWidth
    height: label.implicitHeight

    FontMetrics {
        id: fm
        font.family: root.family
        font.pixelSize: root.pixelSize
    }

    y: root.baselineY - fm.ascent
    readonly property bool hasCjk: /[\u3400-\u9fff]/.test(root.text)

    Text {
        id: label
        text: root.text
        color: root.color
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.letterSpacing: root.letterSpacing
        width: root.width
        elide: root.elide
        renderType: Text.QtRendering
    }
}
