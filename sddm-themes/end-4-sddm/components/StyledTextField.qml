import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

TextField {
    id: field
    property var rootObj: null
    property string placeholder: ""
    property string icon: ""

    implicitHeight: 48
    placeholderText: field.placeholder
    color: rootObj ? rootObj.cOnSurface : "#e6e1e1"
    placeholderTextColor: rootObj ? rootObj.cOnSurfaceVariant : "#cbc5ca"
    font.family: rootObj ? rootObj.fontFamily : "Sans"
    font.pixelSize: 14
    leftPadding: field.icon !== "" ? 44 : 16
    rightPadding: 16
    horizontalAlignment: TextInput.AlignHCenter
    verticalAlignment: TextInput.AlignVCenter

    background: Rectangle {
        radius: 12
        color: rootObj ? rootObj.cSurfaceContainerHigh : "#2b2a2a"
        border.color: field.activeFocus
                      ? (rootObj ? rootObj.cPrimary : "#cbc4cb")
                      : (rootObj ? rootObj.cOutline : "#948f94")
        border.width: 1
    }

    Text {
        visible: field.icon !== ""
        anchors {
            left: parent.left
            leftMargin: 14
            verticalCenter: parent.verticalCenter
        }
        text: field.icon
        font.family: rootObj ? rootObj.fontFamilyIcons : "Material Symbols Rounded"
        font.pixelSize: 20
        color: rootObj ? rootObj.cOnSurfaceVariant : "#cbc5ca"
    }
}
