// Circular avatar with a graceful fallback when the account has no photo.
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property url source: ""
    property int size: 30

    width: size
    height: size

    Image {
        id: photo
        anchors.fill: parent
        source: root.source
        visible: false
        smooth: true
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: width / 2
        color: "black"
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        visible: root.source != ""
        source: photo
        maskEnabled: true
        maskSource: mask
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#F2F2F2"
        visible: root.source == ""
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.22
        width: parent.width * 0.30
        height: width
        radius: width / 2
        color: "#8A8A8A"
        visible: root.source == ""
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.56
        width: parent.width * 0.56
        height: parent.height * 0.32
        radius: width / 2
        color: "#8A8A8A"
        visible: root.source == ""
    }
}
