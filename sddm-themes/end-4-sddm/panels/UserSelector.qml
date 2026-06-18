import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

ColumnLayout {
    id: userSelector
    property var rootObj: null
    signal userSelected(string user)

    spacing: 8

    ListView {
        id: userList
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 220)
        model: userModel
        currentIndex: userModel.lastIndex
        spacing: 8
        clip: true
        keyNavigationEnabled: true

        onCurrentIndexChanged: {
            if (rootObj && currentItem && currentItem.userName !== undefined) {
                rootObj.selectedUser = currentItem.userName;
                userSelector.userSelected(currentItem.userName);
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                event.accepted = true;
                userSelector.userSelected(rootObj.selectedUser);
            }
        }

        delegate: Rectangle {
            id: userItem
            width: userList.width
            height: 64
            radius: 12
            color: userItem.selected
                   ? (rootObj ? rootObj.cPrimaryContainer : "#2d2a2f")
                   : (mouseArea.containsMouse
                      ? (rootObj ? rootObj.cSurfaceContainerHigh : "#2b2a2a")
                      : (rootObj ? rootObj.cSurfaceContainer : "#201f20"))
            border.color: userItem.selected
                          ? (rootObj ? rootObj.cPrimary : "#cbc4cb")
                          : (rootObj ? rootObj.cOutlineVariant : "#49464a")
            border.width: 1

            property string userName: model.name
            property bool selected: rootObj && userName === rootObj.selectedUser

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Avatar {
                    rootObj: userSelector.rootObj
                    source: model.icon || ""
                    fallbackText: model.realName || model.name || "?"
                    size: 40
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: model.realName || model.name
                        color: rootObj ? rootObj.cOnSurface : "#e6e1e1"
                        font.family: rootObj ? rootObj.fontFamily : "Sans"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: model.name
                        color: rootObj ? rootObj.cOnSurfaceVariant : "#cbc5ca"
                        font.family: rootObj ? rootObj.fontFamily : "Sans"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                Text {
                    visible: userItem.selected
                    text: "check"
                    font.family: rootObj ? rootObj.fontFamilyIcons : "Material Symbols Rounded"
                    font.pixelSize: 20
                    color: rootObj ? rootObj.cPrimary : "#cbc4cb"
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    userList.currentIndex = index;
                    userSelector.userSelected(model.name);
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: userList.count === 0
        text: qsTr("No users found")
        color: rootObj ? rootObj.cError : "#ffb4ab"
        font.family: rootObj ? rootObj.fontFamily : "Sans"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
    }
}
