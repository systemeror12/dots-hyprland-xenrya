import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ComboBox {
    id: combo
    property var rootObj: null
    property string icon: ""
    property string placeholder: ""

    implicitHeight: 44

    font.family: rootObj ? rootObj.fontFamily : "Sans"
    font.pixelSize: 14

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: combo.icon !== "" ? 36 : 12
        anchors.rightMargin: 36
        spacing: 8
        Text {
            visible: combo.icon !== ""
            text: combo.icon
            font.family: combo.rootObj ? combo.rootObj.fontFamilyIcons : "Material Symbols Rounded"
            font.pixelSize: 18
            color: combo.rootObj ? combo.rootObj.cOnSurfaceVariant : "#cbc5ca"
        }
        Text {
            Layout.fillWidth: true
            text: combo.currentText || combo.placeholder
            color: combo.rootObj ? combo.rootObj.cOnSurface : "#e6e1e1"
            font.family: combo.rootObj ? combo.rootObj.fontFamily : "Sans"
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        radius: 12
        color: combo.rootObj ? combo.rootObj.cSurfaceContainerHigh : "#2b2a2a"
        border.color: combo.pressed || combo.hovered
                      ? (combo.rootObj ? combo.rootObj.cPrimary : "#cbc4cb")
                      : (combo.rootObj ? combo.rootObj.cOutline : "#948f94")
        border.width: 1
    }

    popup: Popup {
        y: combo.height + 4
        width: combo.width
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
        padding: 8
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: combo.popup.visible ? combo.delegateModel : null
            currentIndex: combo.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle {
            radius: 12
            color: combo.rootObj ? combo.rootObj.cSurfaceContainerHighest : "#363435"
            border.color: combo.rootObj ? combo.rootObj.cOutlineVariant : "#49464a"
            border.width: 1
        }
    }

    delegate: ItemDelegate {
        width: combo.width
        height: 36
        contentItem: Text {
            text: model[combo.textRole]
            color: combo.rootObj ? combo.rootObj.cOnSurface : "#e6e1e1"
            font.family: combo.rootObj ? combo.rootObj.fontFamily : "Sans"
            font.pixelSize: 14
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: parent.highlighted
                  ? (combo.rootObj ? combo.rootObj.cPrimaryContainer : "#2d2a2f")
                  : "transparent"
        }
    }
}
