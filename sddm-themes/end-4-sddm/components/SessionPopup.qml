import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ============================================================
// Popup list for selecting a desktop session.
//
// HOTSPOT: tweak itemHeight, popup radius, or highlight colors
// below to change the session list appearance.
// ============================================================
Popup {
    id: root
    property var rootObj: null
    property int currentIndex: 0

    signal sessionSelected(int index, string name)

    width: parent ? parent.width : 300
    padding: 8

    background: Rectangle {
        radius: 12
        color: root.rootObj ? root.rootObj.cSurfaceContainerHighest : "#363435"
        border.color: root.rootObj ? root.rootObj.cOutlineVariant : "#49464a"
        border.width: 1
    }

    contentItem: ListView {
        id: sessionList
        clip: true
        implicitHeight: contentHeight
        model: sessionModel
        spacing: 4

        delegate: Rectangle {
            id: sessionItem
            width: sessionList.width
            height: 40
            radius: 10
            color: mouseArea.containsMouse
                   ? (root.rootObj ? root.rootObj.cSurfaceContainerHigh : "#2b2a2a")
                   : "transparent"

            property int sessionIndex: index
            property bool selected: sessionIndex === root.currentIndex

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Text {
                    text: "desktop_windows"
                    font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: root.rootObj ? root.rootObj.cOnSurfaceVariant : "#cbc5ca"
                }

                Text {
                    Layout.fillWidth: true
                    text: model.name
                    color: root.rootObj ? root.rootObj.cOnSurface : "#e6e1e1"
                    font.family: root.rootObj ? root.rootObj.fontFamily : "Sans"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    visible: sessionItem.selected
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
                    root.sessionSelected(sessionIndex, model.name);
                    root.close();
                }
            }
        }
    }
}
