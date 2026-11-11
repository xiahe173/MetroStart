// One edge of the Fluent "Reveal" border.
//
// The light is a radial falloff around the pointer: every point of the edge is
// lit by its 2D distance to the pointer, so only the part of an edge near the
// pointer glows (not the whole line). With `uniform` the whole edge is drawn
// at `peak`, which is what the hovered control gets.
import QtQuick

Item {
    id: root
    property bool vertical: true     // edge runs along y (left/right) or x (top/bottom)
    property real start: 0           // edge start along its axis, in design coordinates
    property real length: 1
    property real pointerX: 0
    property real pointerY: 0
    property real edgePos: 0         // fixed coordinate of the edge (x for vertical edges)
    property real peak: 0.25
    property real radius: 115
    property bool uniform: false

    function alphaAt(t) {
        if (root.uniform)
            return root.peak
        if (root.length <= 0)
            return 0
        const along = root.start + t * root.length
        const px = root.vertical ? root.edgePos : along
        const py = root.vertical ? along : root.edgePos
        const d = Math.hypot(px - root.pointerX, py - root.pointerY)
        return root.peak * Math.max(0, 1 - d / root.radius)
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0.000; color: Qt.rgba(1, 1, 1, root.alphaAt(0.000)) }
            GradientStop { position: 0.167; color: Qt.rgba(1, 1, 1, root.alphaAt(0.167)) }
            GradientStop { position: 0.333; color: Qt.rgba(1, 1, 1, root.alphaAt(0.333)) }
            GradientStop { position: 0.500; color: Qt.rgba(1, 1, 1, root.alphaAt(0.500)) }
            GradientStop { position: 0.667; color: Qt.rgba(1, 1, 1, root.alphaAt(0.667)) }
            GradientStop { position: 0.833; color: Qt.rgba(1, 1, 1, root.alphaAt(0.833)) }
            GradientStop { position: 1.000; color: Qt.rgba(1, 1, 1, root.alphaAt(1.000)) }
        }
    }
}
