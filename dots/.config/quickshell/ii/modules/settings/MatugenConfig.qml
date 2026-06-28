import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: matugenPage
    forceWidth: true

    ContentSection {
        icon: "palette"
        title: Translation.tr("Matugen")

        ConfigRow {
            Layout.bottomMargin: 8
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("This wallpaper drives your color theme. It does not affect the Rofi background image.")
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        ConfigRow {
            visible: Config.options.background.matugenThumbnailPath.length > 0
            Item {
                Layout.preferredWidth: 200
                Layout.preferredHeight: 112
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.screenRounding - 4
                    clip: true
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: Config.options.background.matugenThumbnailPath.length > 0
                            ? Config.options.background.matugenThumbnailPath
                            : ""
                        fillMode: Image.PreserveAspectCrop
                    }
                }
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 48
            buttonRadius: Appearance.rounding.full

            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    iconSize: 20
                    text: "wallpaper"
                    fill: 1
                }
                StyledText {
                    text: Config.options.background.matugenWallpaperPath.length > 0
                        ? Translation.tr("Change baseline wallpaper")
                        : Translation.tr("Choose baseline wallpaper")
                }
            }

            onClicked: {
                Quickshell.execDetached(["qs", "-c", "ii", "ipc", "call", "wallpaperSelector", "openWithMode", "matugen-baseline"]);
            }
        }
    }
}
