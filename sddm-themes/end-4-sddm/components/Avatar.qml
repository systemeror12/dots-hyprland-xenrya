import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: avatar
    property var rootObj: null
    property string source: ""
    property string fallbackText: ""
    property int size: 64

    width: size
    height: size
    radius: size / 2
    color: rootObj ? rootObj.cPrimaryContainer : "#2d2a2f"
    border.color: rootObj ? rootObj.cOutlineVariant : "#49464a"
    border.width: 2

    Image {
        id: img
        anchors.fill: parent
        source: avatar.source
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true
    }

    Text {
        anchors.centerIn: parent
        text: avatar.fallbackText.charAt(0).toUpperCase()
        visible: img.status !== Image.Ready
        font.family: avatar.rootObj ? avatar.rootObj.fontFamily : "Sans"
        font.pixelSize: avatar.size * 0.45
        font.weight: Font.Medium
        color: avatar.rootObj ? avatar.rootObj.cOnPrimaryContainer : "#bcb6bc"
    }
}
