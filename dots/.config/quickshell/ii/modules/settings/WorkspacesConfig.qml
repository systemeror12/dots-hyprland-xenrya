import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: workspacesPage
    forceWidth: true

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable per-workspace wallpapers")
            checked: Config.options.workspaces.enabled
            onCheckedChanged: {
                Config.options.workspaces.enabled = checked;
            }
        }

        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 42
            buttonRadius: Appearance.rounding.full
            visible: Config.options.workspaces.enabled

            contentItem: RowLayout {
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol {
                    iconSize: 20
                    text: "open_in_new"
                }
                StyledText {
                    text: Translation.tr("Open picker window")
                }
            }

            onClicked: {
                Quickshell.execDetached(["qs", "-c", "ii", "ipc", "call", "workspaceWallpaperPicker", "toggle"]);
            }
        }
    }

    Repeater {
        model: 10

        ContentSection {
            required property int index
            title: Translation.tr("Workspace") + " " + (index + 1)
            visible: Config.options.workspaces.enabled

            ConfigRow {
                Item {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 45
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        clip: true
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: {
                                const path = Config.options.workspaces.wallpapers[index];
                                return (path && path.length > 0) ? path : "";
                            }
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const path = Config.options.workspaces.wallpapers[index];
                        return (path && path.length > 0)
                            ? path.split("/").pop()
                            : Translation.tr("— none —");
                    }
                    elide: Text.ElideRight
                }

                RippleButtonWithIcon {
                    materialIcon: "wallpaper"
                    mainText: Translation.tr("Set")
                    onClicked: {
                        Quickshell.execDetached(["qs", "-c", "ii", "ipc", "call", "workspaceWallpaperPicker", "openForWorkspace", String(index + 1)]);
                    }
                }

                RippleButtonWithIcon {
                    materialIcon: "close"
                    mainText: Translation.tr("Clear")
                    onClicked: {
                        Wallpapers.clearWorkspaceWallpaper(String(index + 1));
                    }
                }
            }
        }
    }
}
