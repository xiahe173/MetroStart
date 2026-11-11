// Soft radial white glow used for the Reveal interior. It is a pre-rendered
// texture instead of a shader so it works on every Qt Quick backend.
import QtQuick

Item {
    id: root
    property real radius: 260
    property real localX: 0
    property real localY: 0
    property real strength: 0.10

    visible: strength > 0
    clip: true

    Image {
        x: root.localX - root.radius
        y: root.localY - root.radius
        width: root.radius * 2
        height: root.radius * 2
        source: Qt.resolvedUrl("../assets/ui/reveal.png")
        opacity: root.strength
        smooth: true
        fillMode: Image.Stretch
    }
}
