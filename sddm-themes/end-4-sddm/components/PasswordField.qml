import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// ============================================================
// Password field with eye toggle and Quickshell-style shape
// animation.
//
// HOTSPOT: adjust placeholder text, icon size, or shape colors
// here. The row styling comes from IslandRow.
// ============================================================
Item {
    id: root
    property var rootObj: null
    property alias text: field.text
    property bool visiblePassword: false

    signal accepted()
    function forceFieldFocus() { field.forceActiveFocus() }

    height: rootObj ? rootObj.rowHeight : 48

    IslandRow {
        anchors.fill: parent
        rootObj: root.rootObj

        // Eye toggle
        Text {
            id: eyeIcon
            Layout.alignment: Qt.AlignVCenter
            text: root.visiblePassword ? "visibility_off" : "visibility"
            font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
            font.pixelSize: 20
            font.variableAxes: { "FILL": 1, "opsz": 20 }
            color: root.rootObj ? root.rootObj.cOnSurfaceVariant : "#cbc5ca"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.visiblePassword = !root.visiblePassword
            }
        }

        // TextField container
        Item {
            id: fieldContainer
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Hidden-mode shape overlay, placed behind the TextField so it
            // never intercepts input. It auto-scrolls to the last character.
            Flickable {
                id: shapeFlickable
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                visible: !root.visiblePassword && field.text.length > 0
                clip: true
                enabled: false
                interactive: false

                contentWidth: shapes.implicitWidth
                contentHeight: height
                contentX: Math.max(contentWidth - width, 0)

                Behavior on contentX {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                PasswordShapes {
                    id: shapes
                    anchors.verticalCenter: parent.verticalCenter
                    rootObj: root.rootObj
                    length: field.text.length
                }
            }

            TextField {
                id: field
                anchors.fill: parent

                placeholderText: qsTr("Password")
                placeholderTextColor: root.rootObj ? root.rootObj.cOnSurfaceVariant : "#cbc5ca"
                font.family: root.rootObj ? root.rootObj.fontFamily : "Sans"
                font.pixelSize: 14

                // In visible mode show real text; in hidden mode hide it so
                // the shape overlay is visible instead.
                color: root.visiblePassword
                       ? (root.rootObj ? root.rootObj.cOnSurface : "#e6e1e1")
                       : "transparent"
                selectedTextColor: "transparent"
                selectionColor: "transparent"

                background: Item {}

                onAccepted: root.accepted()
            }
        }
    }
}
