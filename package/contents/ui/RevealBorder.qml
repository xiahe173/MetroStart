// Four edges of a Fluent "Reveal" border, positioned in the parent's local
// coordinates. Every point of the border is lit by its distance to the
// pointer, so only the part near the pointer is visible; the radius is much
// smaller than the interior glow.
import QtQuick

Item {
    id: root
    property real pointerX: -1
    property real pointerY: -1
    property real peak: 0.2
    property real radius: 110
    property int thickness: 3
    property bool active: false
    property bool uniform: false

    visible: active

    RevealEdge {
        x: 0; y: 0
        width: root.thickness; height: parent.height
        vertical: true
        start: 0
        length: parent.height
        edgePos: 0
        pointerX: root.pointerX
        pointerY: root.pointerY
        peak: root.peak
        radius: root.radius
        uniform: root.uniform
    }
    RevealEdge {
        x: parent.width - root.thickness; y: 0
        width: root.thickness; height: parent.height
        vertical: true
        start: 0
        length: parent.height
        edgePos: parent.width
        pointerX: root.pointerX
        pointerY: root.pointerY
        peak: root.peak
        radius: root.radius
        uniform: root.uniform
    }
    RevealEdge {
        x: root.thickness; y: 0
        width: parent.width - 2 * root.thickness; height: root.thickness
        vertical: false
        start: root.thickness
        length: parent.width - 2 * root.thickness
        edgePos: 0
        pointerX: root.pointerX
        pointerY: root.pointerY
        peak: root.peak
        radius: root.radius
        uniform: root.uniform
    }
    RevealEdge {
        x: root.thickness; y: parent.height - root.thickness
        width: parent.width - 2 * root.thickness; height: root.thickness
        vertical: false
        start: root.thickness
        length: parent.width - 2 * root.thickness
        edgePos: parent.height
        pointerX: root.pointerX
        pointerY: root.pointerY
        peak: root.peak
        radius: root.radius
        uniform: root.uniform
    }
}
