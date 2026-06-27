import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.wallpaperSelector
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
        active: GlobalStates.workspaceWallpaperPickerOpen

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
                function onDismissed() { GlobalStates.workspaceWallpaperPickerOpen = false; GlobalStates.wallpaperSelectorAssignMode = "global-default"; }
            }

            ColumnLayout {
                id: content
                anchors.fill: parent
                spacing: 4

                // Workspace selector — styled like bar
                Row {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    spacing: 4

                    Repeater {
                        model: root.workspaceChips

                        Rectangle {
                            required property int modelData
                            width: 34
                            height: 34
                            radius: width / 2
                            color: root.selectedWorkspace === modelData
                                ? Appearance.colors.colPrimary
                                : "transparent"
                            border.width: root.activeWorkspace === modelData && root.selectedWorkspace !== modelData ? 2 : 0
                            border.color: Appearance.colors.colPrimary

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                            Behavior on border.width {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: root.selectedWorkspace === modelData
                                    ? Appearance.m3colors.m3onPrimary
                                    : (root.activeWorkspace === modelData
                                        ? Appearance.colors.colPrimary
                                        : Appearance.colors.colOnLayer0)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedWorkspace = modelData;
                                    GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + modelData;
                                }
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
                    onCancel: () => { GlobalStates.workspaceWallpaperPickerOpen = false; }
                }
            }
        }
    }

    IpcHandler {
        target: "workspaceWallpaperPicker"

        function toggle(): void {
            GlobalStates.workspaceWallpaperPickerOpen = !GlobalStates.workspaceWallpaperPickerOpen;
            if (GlobalStates.workspaceWallpaperPickerOpen) {
                root.selectedWorkspace = Math.min(root.activeWorkspace, 10);
                GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + root.selectedWorkspace;
            }
        }

        function openForWorkspace(wsId: string): void {
            const id = parseInt(wsId);
            if (id >= 1 && id <= 10) {
                root.selectedWorkspace = id;
                GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + id;
                GlobalStates.workspaceWallpaperPickerOpen = true;
            }
        }
    }

    GlobalShortcut {
        name: "workspaceWallpaperPickerToggle"
        description: "Toggle per-workspace wallpaper picker"
        onPressed: {
            root.selectedWorkspace = Math.min(root.activeWorkspace, 10);
            GlobalStates.wallpaperSelectorAssignMode = "per-workspace:" + root.selectedWorkspace;
            GlobalStates.workspaceWallpaperPickerOpen = !GlobalStates.workspaceWallpaperPickerOpen;
        }
    }
}
