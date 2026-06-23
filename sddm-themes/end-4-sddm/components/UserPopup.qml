import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ============================================================
// Popup list for selecting a user.
//
// HOTSPOT: tweak itemHeight, popup radius, or highlight colors
// below to change the user list appearance.
// ============================================================
Popup {
    id: root
    property var rootObj: null
    property string currentUser: ""

    signal userSelected(string user, string realName, string icon)

    width: parent ? parent.width : 300
    padding: 8

    background: Rectangle {
        radius: 12
        color: root.rootObj ? root.rootObj.cSurfaceContainerHighest : "#363435"
        border.color: root.rootObj ? root.rootObj.cOutlineVariant : "#49464a"
        border.width: 1
    }

    contentItem: ListView {
        id: userList
        clip: true
        implicitHeight: contentHeight
        model: userModel
        spacing: 4

        delegate: Rectangle {
            id: userItem
            width: userList.width
            height: 44
            radius: 10
            color: mouseArea.containsMouse
                   ? (root.rootObj ? root.rootObj.cSurfaceContainerHigh : "#2b2a2a")
                   : "transparent"

            property string userName: model.name
            property bool selected: userName === root.currentUser

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Avatar {
                    rootObj: root.rootObj
                    source: model.icon || ""
                    fallbackText: model.realName || model.name || "?"
                    size: 28
                }

                Text {
                    Layout.fillWidth: true
                    text: model.realName || model.name
                    color: root.rootObj ? root.rootObj.cOnSurface : "#e6e1e1"
                    font.family: root.rootObj ? root.rootObj.fontFamily : "Sans"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    visible: userItem.selected
                    text: "check"
                    font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: root.rootObj ? root.rootObj.cPrimary : "#cbc4cb"
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    var rn = model.realName || userName;
                    var ic = model.icon || "";
                    root.userSelected(userName, rn, ic);
                    root.close();
                }
            }
        }
    }
}
