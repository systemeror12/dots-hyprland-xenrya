import QtQuick 2.15
import QtQuick.Layouts 1.15

// ============================================================
// Power actions row: sleep, reboot, shutdown.
//
// HOTSPOT: change buttonSize, iconSize, colors, or spacing
// below. Add/remove buttons by editing the Repeater model.
// ============================================================
Row {
    id: root
    property var rootObj: null
    property int buttonSize: root.rootObj ? root.rootObj.powerButtonSize : 40
    property int buttonSpacing: root.rootObj ? root.rootObj.powerButtonSpacing : 12

    spacing: buttonSpacing

    // Each entry: icon, SDDM action function name
    property var actions: [
        { icon: "bedtime", action: function() { sddm.suspend() } },
        { icon: "restart_alt", action: function() { sddm.reboot() } },
        { icon: "power_settings_new", action: function() { sddm.powerOff() } }
    ]

    Repeater {
        model: root.actions

        delegate: Rectangle {
            id: btn
            required property var modelData

            width: root.buttonSize
            height: root.buttonSize
            radius: width / 2
            color: mouseArea.containsMouse
                   ? (root.rootObj ? root.rootObj.cSurfaceContainerHigh : "#2b2a2a")
                   : (root.rootObj ? root.rootObj.cSurfaceContainer : "#201f20")
            border.color: root.rootObj ? root.rootObj.cOutlineVariant : "#49464a"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: btn.modelData.icon
                font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
                font.pixelSize: root.buttonSize * 0.5
                color: root.rootObj ? root.rootObj.cOnSurfaceVariant : "#cbc5ca"
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: btn.modelData.action()
            }
        }
    }
}
