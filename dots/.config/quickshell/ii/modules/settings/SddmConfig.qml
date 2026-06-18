import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: sddmPage
    forceWidth: true

    property var themeList: []
    property int currentThemeIndex: -1

    Process {
        id: listThemesProc
        command: ["bash", "-c", "ls -1 /usr/share/sddm/themes 2>/dev/null || true"]
        stdout: SplitParser {
            onRead: data => {
                var themes = data.trim().split("\n").filter(t => t.length > 0);
                sddmPage.themeList = themes;
                sddmPage.currentThemeIndex = themes.indexOf(Config.options.sddm.activeTheme);
                if (sddmPage.currentThemeIndex < 0 && themes.length > 0) {
                    sddmPage.currentThemeIndex = 0;
                }
            }
        }
    }

    Component.onCompleted: listThemesProc.running = true

    ContentSection {
        icon: "login"
        title: Translation.tr("SDDM Theme")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Use custom SDDM theme")
            checked: Config.options.sddm.enableCustomTheme
            onCheckedChanged: {
                Config.options.sddm.enableCustomTheme = checked;
                if (checked) applyTheme();
            }
        }

        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Sync wallpaper to SDDM")
            checked: Config.options.sddm.syncWallpaper
            onCheckedChanged: {
                Config.options.sddm.syncWallpaper = checked;
            }
            StyledToolTip {
                text: Translation.tr("Copies the current wallpaper to the SDDM greeter on every wallpaper change")
            }
        }

        ContentSubsection {
            title: Translation.tr("Active theme")
            visible: Config.options.sddm.enableCustomTheme

            ConfigRow {
                StyledComboBox {
                    id: themeCombo
                    Layout.fillWidth: true
                    textRole: "modelData"
                    model: sddmPage.themeList
                    currentIndex: sddmPage.currentThemeIndex
                    onActivated: index => {
                        sddmPage.currentThemeIndex = index;
                        Config.options.sddm.activeTheme = sddmPage.themeList[index];
                        applyTheme();
                    }
                }

                RippleButtonWithIcon {
                    id: testThemeButton
                    materialIcon: "preview"
                    mainText: Translation.tr("Test")
                    enabled: Config.options.sddm.activeTheme !== ""
                    onClicked: {
                        Quickshell.execDetached([
                            "sddm-greeter-qt6",
                            "--test-mode",
                            "--theme",
                            "/usr/share/sddm/themes/" + Config.options.sddm.activeTheme
                        ]);
                    }
                }
            }
        }
    }

    function applyTheme() {
        if (!Config.options.sddm.enableCustomTheme || Config.options.sddm.activeTheme === "") return;
        Quickshell.execDetached([
            "pkexec",
            `${Directories.scriptPath}/sddm/apply-theme.sh`,
            Config.options.sddm.activeTheme
        ]);
    }
}
