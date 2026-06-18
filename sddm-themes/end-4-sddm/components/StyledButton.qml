import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Button {
    id: button
    property var rootObj: null
    property bool primary: false
    property string iconText: ""

    implicitHeight: 44

    contentItem: RowLayout {
        anchors.centerIn: parent
        spacing: 8
        Text {
            visible: button.iconText !== ""
            text: button.iconText
            font.family: button.rootObj ? button.rootObj.fontFamilyIcons : "Material Symbols Rounded"
            font.pixelSize: 18
            color: button.primary
                  ? (button.rootObj ? button.rootObj.cOnPrimary : "#322f34")
                  : (button.rootObj ? button.rootObj.cOnSurface : "#e6e1e1")
        }
        Text {
            text: button.text
            font.family: button.rootObj ? button.rootObj.fontFamily : "Sans"
            font.pixelSize: 14
            font.weight: Font.Medium
            color: button.primary
                  ? (button.rootObj ? button.rootObj.cOnPrimary : "#322f34")
                  : (button.rootObj ? button.rootObj.cOnSurface : "#e6e1e1")
        }
    }

    background: Rectangle {
        radius: 12
        color: {
            if (!button.rootObj) return "#201f20";
            var base = button.primary ? button.rootObj.cPrimary : button.rootObj.cSurfaceContainerHigh;
            if (button.down) return Qt.darker(base, 1.15);
            if (button.hovered) return Qt.lighter(base, 1.08);
            return base;
        }
        border.color: button.primary
                      ? (button.rootObj ? button.rootObj.cPrimary : "#cbc4cb")
                      : (button.rootObj ? button.rootObj.cOutline : "#948f94")
        border.width: 1
    }
}
