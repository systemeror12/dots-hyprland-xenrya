import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects 6.0
import "components"
import "panels"

Rectangle {
    id: root
    anchors.fill: parent
    color: cfg.color("background", "#141313")

    // ============================================================
    // HOTSPOT: Config helpers
    // Read string or color values from theme.conf / theme.conf.user.
    // Colors must be in #RRGGBB format.
    // ============================================================
    QtObject {
        id: cfg
        function string(key, fallback) {
            var v = config[key];
            return (v !== undefined && v !== "") ? v : fallback;
        }
        function color(key, fallback) {
            var v = config[key];
            if (v === undefined || v === "") return fallback;
            return Qt.rgba(parseInt(v.slice(1, 3), 16) / 255,
                           parseInt(v.slice(3, 5), 16) / 255,
                           parseInt(v.slice(5, 7), 16) / 255,
                           1);
        }
    }

    // ============================================================
    // HOTSPOT: Material You color tokens
    // These are filled from matugen's colors.json by
    // update-active-theme.sh. Edit theme.conf defaults here if you
    // want different fallback colors.
    // ============================================================
    property color cBackground:              cfg.color("background", "#141313")
    property color cSurface:                 cfg.color("surface", "#141313")
    property color cSurfaceContainerLow:     cfg.color("surface_container_low", "#1c1b1c")
    property color cSurfaceContainer:        cfg.color("surface_container", "#201f20")
    property color cSurfaceContainerHigh:    cfg.color("surface_container_high", "#2b2a2a")
    property color cSurfaceContainerHighest: cfg.color("surface_container_highest", "#363435")
    property color cPrimary:                 cfg.color("primary", "#cbc4cb")
    property color cOnPrimary:               cfg.color("on_primary", "#322f34")
    property color cPrimaryContainer:        cfg.color("primary_container", "#2d2a2f")
    property color cOnPrimaryContainer:      cfg.color("on_primary_container", "#bcb6bc")
    property color cSecondary:               cfg.color("secondary", "#cac5c8")
    property color cOnSecondary:             cfg.color("on_secondary", "#323032")
    property color cSecondaryContainer:      cfg.color("secondary_container", "#4d4b4d")
    property color cOnSecondaryContainer:    cfg.color("on_secondary_container", "#ece6e9")
    property color cOutline:                 cfg.color("outline", "#948f94")
    property color cOutlineVariant:          cfg.color("outline_variant", "#49464a")
    property color cOnSurface:               cfg.color("on_surface", "#e6e1e1")
    property color cOnSurfaceVariant:        cfg.color("on_surface_variant", "#cbc5ca")
    property color cError:                   cfg.color("error", "#ffb4ab")
    property color cOnError:                 cfg.color("on_error", "#690005")
    property color cScrim:                   cfg.color("scrim", "#000000")

    property string fontFamily:      cfg.string("fontFamily", "Google Sans Flex")
    property string fontFamilyIcons: cfg.string("fontFamilyIcons", "Material Symbols Rounded")
    property string fontFamilyMono:  cfg.string("fontFamilyMono", "JetBrains Mono NF")
    property string wallpaperPath:   cfg.string("wallpaperPath", "assets/default_wallpaper.png")

    // ============================================================
    // HOTSPOT: Geometry knobs
    // All of these can be changed in theme.conf without editing QML.
    // ============================================================
    property int clockTopMargin:       parseInt(cfg.string("clockTopMargin", "60"))
    property int clockLeftMargin:      parseInt(cfg.string("clockLeftMargin", "60"))
    property int formTopMargin:        parseInt(cfg.string("formTopMargin", "40"))
    property int formLeftMargin:       parseInt(cfg.string("formLeftMargin", "60"))
    property int formWidth:            parseInt(cfg.string("formWidth", "300"))
    property int rowHeight:            parseInt(cfg.string("rowHeight", "48"))
    property int rowSpacing:           parseInt(cfg.string("rowSpacing", "12"))
    property int buttonHeight:         parseInt(cfg.string("buttonHeight", "48"))
    property int powerButtonSize:      parseInt(cfg.string("powerButtonSize", "40"))
    property int powerButtonSpacing:   parseInt(cfg.string("powerButtonSpacing", "12"))
    property int sessionButtonHeight:  parseInt(cfg.string("sessionButtonHeight", "40"))
    property string timeFormat:        cfg.string("timeFormat", "hh:mm")
    property string dateFormat:        cfg.string("dateFormat", "dddd d")
    property bool useLeftScrim:        cfg.string("useLeftScrim", "false") === "true"
    property int scrimWidth:           parseInt(cfg.string("scrimWidth", "500"))

    // ---- Background ---------------------------------------------------------
    Image {
        id: bgImage
        anchors.fill: parent
        source: root.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        cache: false
    }

    // Optional left-side scrim for readability on bright wallpapers.
    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: root.scrimWidth
        visible: root.useLeftScrim
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(root.cScrim.r, root.cScrim.g, root.cScrim.b, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(root.cScrim.r, root.cScrim.g, root.cScrim.b, 0) }
        }
    }

    // ---- Clock --------------------------------------------------------------
    Clock {
        id: clock
        anchors {
            top: parent.top
            topMargin: root.clockTopMargin
            left: parent.left
            leftMargin: root.clockLeftMargin
        }
        rootObj: root
    }

    // ---- Login form ---------------------------------------------------------
    LoginForm {
        id: loginForm
        anchors {
            top: clock.bottom
            topMargin: root.formTopMargin
            left: parent.left
            leftMargin: root.formLeftMargin
        }
        width: root.formWidth
        rootObj: root
    }
}
