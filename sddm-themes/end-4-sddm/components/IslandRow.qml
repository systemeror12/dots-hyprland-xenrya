import QtQuick 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects 6.0

// ============================================================
// HOTSPOT: Reusable pill toolbar row
// Change rowRadius, backgroundColor, borderColor, etc. in the
// parent or in theme.conf to tweak the look of every row.
// ============================================================
Rectangle {
    id: root
    property var rootObj: null
    property real rowOpacity: 1.0

    // Default colors: Quickshell lockscreen toolbar style
    property color backgroundColor: rootObj ? rootObj.cSurfaceContainer : "#201f20"
    property color borderColor: rootObj ? rootObj.cOutlineVariant : "#49464a"

    radius: height / 2
    color: Qt.rgba(backgroundColor.r, backgroundColor.g, backgroundColor.b, rowOpacity)
    border.color: borderColor
    border.width: 1

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: 4
        radius: 16
        samples: 25
        color: Qt.rgba(0, 0, 0, 0.25)
    }

    default property alias content: layout.children

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
    }
}
