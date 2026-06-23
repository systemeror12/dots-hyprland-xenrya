import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

// ============================================================
// Left-aligned login form.
//
// HOTSPOT: Layout order and spacing are controlled here.
// Reorder or hide rows by editing the ColumnLayout children.
// ============================================================
ColumnLayout {
    id: root
    property var rootObj: null

    spacing: rootObj ? rootObj.rowSpacing : 12

    // Hidden list views let us read SDDM model data for the
    // currently selected user/session.
    ListView {
        id: userList
        visible: false
        width: 1
        height: 1
        model: userModel
        currentIndex: userModel.count > 0 ? userModel.lastIndex : -1
        onCurrentIndexChanged: root.syncUserFromList()
        delegate: Item {
            property string userName: model.name
            property string realName: model.realName || model.name
            property string icon: model.icon || ""
        }
    }

    ListView {
        id: sessionList
        visible: false
        width: 1
        height: 1
        model: sessionModel
        currentIndex: sessionModel.count > 0 ? sessionModel.lastIndex : -1
        onCurrentIndexChanged: root.syncSessionFromList()
        delegate: Item {
            property string sessionName: model.name
        }
    }

    Component.onCompleted: {
        syncUserFromList();
        syncSessionFromList();
        passwordField.forceFieldFocus();
    }

    // ---- User selector row --------------------------------------------------
    Item {
        id: userRowWrapper
        Layout.fillWidth: true
        Layout.preferredHeight: rootObj ? rootObj.rowHeight : 48

        IslandRow {
            id: userRow
            anchors.fill: parent
            rootObj: root.rootObj

            Avatar {
                id: userAvatar
                Layout.alignment: Qt.AlignVCenter
                rootObj: root.rootObj
                source: root.selectedUserIcon
                fallbackText: root.selectedUserRealName
                size: rootObj ? rootObj.rowHeight - 16 : 32
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.selectedUserRealName
                color: root.rootObj ? root.rootObj.cOnSurface : "#e6e1e1"
                font.family: root.rootObj ? root.rootObj.fontFamily : "Sans"
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: userModel.count > 1
                text: "expand_more"
                font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
                font.pixelSize: 20
                color: root.rootObj ? root.rootObj.cOnSurfaceVariant : "#cbc5ca"
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: userModel.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (userModel.count > 1) userPopup.open();
            }
        }
    }

    UserPopup {
        id: userPopup
        x: 0
        y: userRowWrapper.height + 8
        rootObj: root.rootObj
        currentUser: root.selectedUser
        onUserSelected: (user, realName, icon) => {
            root.selectedUser = user;
            root.selectedUserRealName = realName || user;
            root.selectedUserIcon = icon || "";
            passwordField.forceFieldFocus();
        }
    }

    // ---- Password field -----------------------------------------------------
    PasswordField {
        id: passwordField
        Layout.fillWidth: true
        rootObj: root.rootObj
        onAccepted: root.tryLogin()
    }

    // ---- Error label --------------------------------------------------------
    Text {
        id: errorLabel
        Layout.fillWidth: true
        text: ""
        color: root.rootObj ? root.rootObj.cError : "#ffb4ab"
        font.family: root.rootObj ? root.rootObj.fontFamily : "Sans"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        visible: text !== ""
    }

    // ---- Login button -------------------------------------------------------
    Rectangle {
        id: loginButton
        Layout.fillWidth: true
        Layout.preferredHeight: rootObj ? rootObj.buttonHeight : 48
        radius: height / 2
        color: loginMouseArea.containsMouse
               ? Qt.lighter(root.rootObj ? root.rootObj.cPrimary : "#cbc4cb", 1.08)
               : (root.rootObj ? root.rootObj.cPrimary : "#cbc4cb")

        Text {
            anchors.centerIn: parent
            text: qsTr("Login")
            color: root.rootObj ? root.rootObj.cOnPrimary : "#322f34"
            font.family: root.rootObj ? root.rootObj.fontFamily : "Sans"
            font.pixelSize: 14
            font.weight: Font.Medium
        }

        MouseArea {
            id: loginMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.tryLogin()
        }
    }

    // ---- Session selector ---------------------------------------------------
    Item {
        id: sessionRowWrapper
        Layout.fillWidth: true
        Layout.preferredHeight: rootObj ? rootObj.sessionButtonHeight : 40

        IslandRow {
            id: sessionRow
            anchors.fill: parent
            rootObj: root.rootObj

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "desktop_windows"
                font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
                font.pixelSize: 18
                color: root.rootObj ? root.rootObj.cOnSurfaceVariant : "#cbc5ca"
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.selectedSessionName
                color: root.rootObj ? root.rootObj.cOnSurface : "#e6e1e1"
                font.family: root.rootObj ? root.rootObj.fontFamily : "Sans"
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "expand_more"
                font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
                font.pixelSize: 20
                color: root.rootObj ? root.rootObj.cOnSurfaceVariant : "#cbc5ca"
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sessionPopup.open()
        }
    }

    SessionPopup {
        id: sessionPopup
        x: 0
        y: sessionRowWrapper.height + 8
        rootObj: root.rootObj
        currentIndex: root.selectedSessionIndex
        onSessionSelected: (index, name) => {
            root.selectedSessionIndex = index;
            root.selectedSessionName = name || "";
            passwordField.forceFieldFocus();
        }
    }

    // ---- Power actions ------------------------------------------------------
    PowerRow {
        id: powerRow
        Layout.alignment: Qt.AlignHCenter
        rootObj: root.rootObj
    }

    // ---- State & helpers ----------------------------------------------------
    property string selectedUser: ""
    property string selectedUserRealName: qsTr("No users found")
    property string selectedUserIcon: ""
    property int selectedSessionIndex: 0
    property string selectedSessionName: qsTr("Session")

    function syncUserFromList() {
        if (!userList.currentItem) {
            root.selectedUser = "";
            root.selectedUserRealName = qsTr("No users found");
            root.selectedUserIcon = "";
            return;
        }
        root.selectedUser = userList.currentItem.userName || "";
        root.selectedUserRealName = userList.currentItem.realName || root.selectedUser;
        root.selectedUserIcon = userList.currentItem.icon || "";
    }

    function syncSessionFromList() {
        if (!sessionList.currentItem) {
            root.selectedSessionName = qsTr("Session");
            root.selectedSessionIndex = 0;
            return;
        }
        root.selectedSessionIndex = sessionList.currentIndex;
        root.selectedSessionName = sessionList.currentItem.sessionName || "";
    }

    function tryLogin() {
        if (root.selectedUser === "") {
            errorLabel.text = qsTr("Please select a user");
            return;
        }
        errorLabel.text = "";
        sddm.login(root.selectedUser, passwordField.text, root.selectedSessionIndex);
    }
}
