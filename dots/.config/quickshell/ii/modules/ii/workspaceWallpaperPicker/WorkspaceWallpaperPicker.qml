import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property int activeWorkspace: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    // Chip model for workspace selector
    property var workspaceChips: [1,2,3,4,5,6,7,8,9,10]
    property int selectedWorkspace: Math.min(root.activeWorkspace, 10)

    Loader {
        id: pickerLoader
        active: GlobalStates.wallpaperSelectorOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:workspaceWallpaperPicker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            margins {
                top: Config?.options.bar.vertical ? Appearance.sizes.hyprlandGapsOut : Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            }

            mask: Region { item: content }

            implicitHeight: Appearance.sizes.wallpaperSelectorHeight + 60
            implicitWidth: Appearance.sizes.wallpaperSelectorWidth

            Component.onCompleted: GlobalFocusGrab.addDismissable(panelWindow)
            Component.onDestruction: GlobalFocusGrab.removeDismissable(panelWindow)
            Connections {
                target: GlobalFocusGrab
                function onDismissed() { GlobalStates.wallpaperSelectorOpen = false; }
            }

            ColumnLayout {
                id: content
                anchors.fill: parent
                spacing: 4

                // Workspace chip selector
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    spacing: 4

                    StyledText {
                        text: Translation.tr("Assign to:")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                    }

                    Repeater {
                        model: root.workspaceChips
                        RippleButton {
                            required property int modelData
                            implicitWidth: 36
                            implicitHeight: 36
                            buttonRadius: Appearance.rounding.full
                            toggled: root.selectedWorkspace === modelData
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Appearance.font.pixelSize.small
                            }

                            onClicked: {
                                root.selectedWorkspace = modelData;
                                GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + modelData;
                            }
                        }
                    }
                }

                // Wallpaper grid
                WallpaperSelectorContent {
                    id: wsContent
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    assignMode: "per-workspace:" + root.selectedWorkspace
                }
            }
        }
    }

    IpcHandler {
        target: "workspaceWallpaperPicker"

        function toggle(): void {
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen;
            if (GlobalStates.wallpaperSelectorOpen) {
                root.selectedWorkspace = Math.min(root.activeWorkspace, 10);
                GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + root.selectedWorkspace;
            }
        }
    }

    GlobalShortcut {
        name: "workspaceWallpaperPickerToggle"
        description: "Toggle per-workspace wallpaper picker"
        onPressed: {
            root.selectedWorkspace = Math.min(root.activeWorkspace, 10);
            GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + root.selectedWorkspace;
            GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen;
        }
    }
}
