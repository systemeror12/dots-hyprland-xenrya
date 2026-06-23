import QtQuick 2.15

// ============================================================
// Quickshell-style password typing animation.
// Each typed character is shown as a small shape that pops in.
//
// HOTSPOT: change the shapeIcons array to use different
// Material Symbols icons, or adjust charSize / colors.
// ============================================================
Row {
    id: root
    property var rootObj: null
    property int length: 0
    property int charSize: 20
    property color color: rootObj ? rootObj.cPrimary : "#cbc4cb"
    property color finalColor: rootObj ? rootObj.cOnSurface : "#e6e1e1"

    // Cycle of Material Symbols used as password shapes.
    property var shapeIcons: [
        "circle",
        "square",
        "pentagon",
        "change_history",
        "star",
        "hexagon",
        "favorite"
    ]

    spacing: 4
    height: charSize

    Repeater {
        model: root.length

        delegate: Text {
            id: shape
            required property int index

            text: root.shapeIcons[index % root.shapeIcons.length]
            font.family: root.rootObj ? root.rootObj.fontFamilyIcons : "Material Symbols Rounded"
            font.pixelSize: root.charSize
            font.variableAxes: { "FILL": 1, "opsz": root.charSize }
            color: root.color
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            opacity: 0
            scale: 0.5

            Component.onCompleted: appearAnim.start()

            ParallelAnimation {
                id: appearAnim
                NumberAnimation { target: shape; property: "opacity"; to: 1; duration: 50; easing.type: Easing.InOutQuad }
                NumberAnimation { target: shape; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack }
                ColorAnimation { target: shape; property: "color"; from: root.color; to: root.finalColor; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }
    }
}
