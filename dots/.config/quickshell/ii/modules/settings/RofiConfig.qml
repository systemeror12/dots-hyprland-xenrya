import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: rofiPage
    forceWidth: true

    ContentSection {
        icon: "apps"
        title: Translation.tr("Rofi wallpaper")

        ConfigRow {
            Layout.bottomMargin: 8
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: Appearance.colors.colOnLayer0
                text: Translation.tr("Falls back to the desktop wallpaper when not set.")
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        ConfigRow {
            visible: Config.options.rofi.wallpaperPath.length > 0
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
                        source: Config.options.rofi.wallpaperPath.length > 0
                            ? Config.options.rofi.wallpaperPath
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
                    text: Config.options.rofi.wallpaperPath.length > 0
                        ? Translation.tr("Change wallpaper")
                        : Translation.tr("Choose wallpaper")
                }
            }

            onClicked: {
                Quickshell.execDetached(["qs", "-c", "ii", "ipc", "call", "wallpaperSelector", "openWithMode", "rofi"]);
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 48
            buttonRadius: Appearance.rounding.full
            visible: Config.options.rofi.wallpaperPath.length > 0

            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    iconSize: 20
                    text: "close"
                    fill: 1
                }
                StyledText {
                    text: Translation.tr("Clear")
                }
            }

            onClicked: {
                Wallpapers.clearRofiWallpaper();
            }
        }
    }
}
