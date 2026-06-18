import QtQuick 2.15
import Qt5Compat.GraphicalEffects 6.0

Rectangle {
    id: panel
    property var rootObj: null
    property real panelOpacity: rootObj ? rootObj.panelOpacity : 0.92
    property color panelColor: rootObj ? rootObj.cSurfaceContainerLow : "#1c1b1c"
    property color borderColor: rootObj ? rootObj.cOutlineVariant : "#49464a"
    property var blurSource: null

    color: Qt.rgba(panelColor.r, panelColor.g, panelColor.b, panelOpacity)
    border.color: borderColor
    border.width: 1

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: 8
        radius: 24
        samples: 25
        color: Qt.rgba(0, 0, 0, 0.35)
    }
}
