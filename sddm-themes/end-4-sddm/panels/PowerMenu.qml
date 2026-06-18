import QtQuick 2.15
import QtQuick.Layouts 1.15
import "../components"

RowLayout {
    id: powerMenu
    property var rootObj: null
    spacing: 12

    component PowerButton: StyledButton {
        rootObj: powerMenu.rootObj
        implicitWidth: 40
        text: ""
    }

    PowerButton {
        visible: sddm.canSuspend
        iconText: "bedtime"
        onClicked: sddm.suspend()
    }
    PowerButton {
        visible: sddm.canReboot
        iconText: "restart_alt"
        onClicked: sddm.reboot()
    }
    PowerButton {
        visible: sddm.canPowerOff
        iconText: "power_settings_new"
        onClicked: sddm.powerOff()
    }
}
