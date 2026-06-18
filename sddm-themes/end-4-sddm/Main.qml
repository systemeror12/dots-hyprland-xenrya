import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects 6.0
import "components"
import "panels"

Rectangle {
    id: root
    anchors.fill: parent
    color: cfg.color("background", "#141313")

    // ---- Config helpers -----------------------------------------------------
    QtObject {
        id: cfg
        function string(key, fallback) {
            var v = config[key];
            return (v !== undefined && v !== "") ? v : fallback;
        }
        function color(key, fallback) {
            var v = config[key];
            return Qt.rgba(parseInt(v.slice(1,3),16)/255,
                           parseInt(v.slice(3,5),16)/255,
                           parseInt(v.slice(5,7),16)/255,
                           1);
        }
    }

    property color cBackground:        cfg.color("background", "#141313")
    property color cSurface:           cfg.color("surface", "#141313")
    property color cSurfaceContainerLow: cfg.color("surfaceContainerLow", "#1c1b1c")
    property color cSurfaceContainer:  cfg.color("surfaceContainer", "#201f20")
    property color cSurfaceContainerHigh: cfg.color("surfaceContainerHigh", "#2b2a2a")
    property color cSurfaceContainerHighest: cfg.color("surfaceContainerHighest", "#363435")
    property color cPrimary:           cfg.color("primary", "#cbc4cb")
    property color cOnPrimary:         cfg.color("onPrimary", "#322f34")
    property color cPrimaryContainer:  cfg.color("primaryContainer", "#2d2a2f")
    property color cOnPrimaryContainer: cfg.color("onPrimaryContainer", "#bcb6bc")
    property color cSecondary:         cfg.color("secondary", "#cac5c8")
    property color cOnSecondary:       cfg.color("onSecondary", "#323032")
    property color cSecondaryContainer: cfg.color("secondaryContainer", "#4d4b4d")
    property color cOnSecondaryContainer: cfg.color("onSecondaryContainer", "#ece6e9")
    property color cOutline:           cfg.color("outline", "#948f94")
    property color cOutlineVariant:    cfg.color("outlineVariant", "#49464a")
    property color cOnSurface:         cfg.color("onSurface", "#e6e1e1")
    property color cOnSurfaceVariant:  cfg.color("onSurfaceVariant", "#cbc5ca")
    property color cError:             cfg.color("error", "#ffb4ab")
    property color cOnError:           cfg.color("onError", "#690005")
    property color cScrim:             cfg.color("scrim", "#000000")

    property string fontFamily:        cfg.string("fontFamily", "Google Sans Flex")
    property string fontFamilyIcons:   cfg.string("fontFamilyIcons", "Material Symbols Rounded")
    property string fontFamilyMono:    cfg.string("fontFamilyMono", "JetBrains Mono NF")
    property string wallpaperPath:     cfg.string("wallpaperPath", "assets/default_wallpaper.png")

    property int panelWidth:           parseInt(cfg.string("panelWidth", "420"))
    property int panelRadius:          parseInt(cfg.string("panelRadius", "18"))
    property real panelOpacity:        parseFloat(cfg.string("panelOpacity", "0.92"))

    property string selectedUser:      sddm.defaultUser || ""

    // ---- Background ---------------------------------------------------------
    Image {
        id: bgImage
        anchors.fill: parent
        source: root.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        cache: false
    }

    Rectangle {
        anchors.fill: parent
        color: root.cScrim
        opacity: 0.40
    }

    // ---- Top bar ------------------------------------------------------------
    RowLayout {
        anchors {
            top: parent.top
            right: parent.right
            margins: 24
        }
        spacing: 12

        PowerMenu {
            rootObj: root
        }
    }

    // ---- Clock --------------------------------------------------------------
    Clock {
        anchors {
            top: parent.top
            topMargin: 80
            horizontalCenter: parent.horizontalCenter
        }
        rootObj: root
    }

    // ---- Login panel --------------------------------------------------------
    GlassPanel {
        id: loginPanel
        rootObj: root
        width: root.panelWidth
        height: contentLayout.implicitHeight + 48
        radius: root.panelRadius
        anchors.centerIn: parent

        ColumnLayout {
            id: contentLayout
            anchors {
                fill: parent
                margins: 24
            }
            spacing: 18

            UserSelector {
                rootObj: root
                Layout.fillWidth: true
                onUserSelected: user => {
                    root.selectedUser = user;
                    passwordInput.forceActiveFocus();
                }
            }

            StyledTextField {
                id: passwordInput
                rootObj: root
                Layout.fillWidth: true
                placeholder: qsTr("Password")
                echoMode: TextInput.Password
                icon: "lock"
                onAccepted: root.tryLogin()
            }

            StyledButton {
                rootObj: root
                Layout.fillWidth: true
                text: qsTr("Login")
                primary: true
                onClicked: root.tryLogin()
            }

            StyledComboBox {
                id: sessionBox
                rootObj: root
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                icon: "desktop_windows"
                placeholder: qsTr("Session")
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ---- Caps / error label -------------------------------------------------
    Text {
        id: statusLabel
        anchors {
            top: loginPanel.bottom
            topMargin: 16
            horizontalCenter: parent.horizontalCenter
        }
        color: root.cError
        font.family: root.fontFamily
        font.pixelSize: 13
        text: ""
        visible: text !== ""
    }

    // ---- Functions ----------------------------------------------------------
    function tryLogin() {
        if (root.selectedUser === "") {
            statusLabel.text = qsTr("Please select a user");
            return;
        }
        statusLabel.text = "";
        sddm.login(root.selectedUser, passwordInput.text, sessionBox.currentIndex);
    }

    Component.onCompleted: {
        if (root.selectedUser !== "") passwordInput.forceActiveFocus();
    }
}
