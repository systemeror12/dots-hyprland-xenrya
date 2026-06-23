import QtQuick 2.15

Column {
    id: clockRoot
    property var rootObj: null
    spacing: 4

    Text {
        id: timeText
        color: rootObj ? rootObj.cOnSurface : "#e6e1e1"
        font.family: rootObj ? rootObj.fontFamily : "Sans"
        font.pixelSize: 72
        font.weight: Font.Light
        text: Qt.formatTime(new Date(), rootObj ? rootObj.timeFormat : "hh:mm")
    }

    Text {
        id: dateText
        color: rootObj ? rootObj.cOnSurfaceVariant : "#cbc5ca"
        font.family: rootObj ? rootObj.fontFamily : "Sans"
        font.pixelSize: 18
        text: Qt.formatDate(new Date(), rootObj ? rootObj.dateFormat : "dddd d")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatTime(new Date(), rootObj ? rootObj.timeFormat : "hh:mm");
            dateText.text = Qt.formatDate(new Date(), rootObj ? rootObj.dateFormat : "dddd d");
        }
    }
}
