pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running

    // Floating panel geometry — narrow vertical card
    readonly property real panelScale: Math.min(1, (root.screen?.height ?? 1080) / 1080)
    readonly property int panelWidth: Math.round(420 * panelScale)
    readonly property int panelHeight: Math.round(600 * panelScale)
    readonly property int panelRadius: Appearance.rounding.large * 1.5

    color: "transparent"

    Connections {
        target: root.lock

        function onUnlock(): void {
            unlockAnim.start();
        }
    }

    // Unlock: shrink panel back to icon → release session lock
    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            Anim {
                target: lockContent
                properties: "implicitWidth,implicitHeight"
                to: lockContent.iconSize
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: lockBg
                property: "radius"
                to: lockContent.iconSize / 4 * Appearance.rounding.scale
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: centerPanel
                property: "scale"
                to: 0
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: centerPanel
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.large
            }
            Anim {
                target: background
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.large
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Appearance.anim.durations.small
                }
                Anim {
                    target: lockContent
                    property: "opacity"
                    to: 0
                }
            }
        }
        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    // Init: spin icon → expand to floating panel
    ParallelAnimation {
        id: initAnim

        running: true

        Anim {
            target: background
            property: "opacity"
            to: 1
            duration: Appearance.anim.durations.large
        }
        Anim {
            target: wallpaperFallback
            property: "opacity"
            to: 0
            duration: Appearance.anim.durations.large
        }
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: lockContent
                    property: "scale"
                    to: 1
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
                }
                Anim {
                    target: lockContent
                    property: "rotation"
                    to: 360
                    duration: Appearance.anim.durations.expressiveFastSpatial
                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                }
            }
            ParallelAnimation {
                Anim {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    target: lockIcon
                    property: "opacity"
                    to: 0
                }
                Anim {
                    target: centerPanel
                    property: "opacity"
                    to: 1
                }
                Anim {
                    target: centerPanel
                    property: "scale"
                    to: 1
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
                Anim {
                    target: lockBg
                    property: "radius"
                    to: root.panelRadius
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
                Anim {
                    target: lockContent
                    property: "implicitWidth"
                    to: root.panelWidth
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
                Anim {
                    target: lockContent
                    property: "implicitHeight"
                    to: root.panelHeight
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }
        }
    }

    // ── Background layers ──────────────────────────────────────────────────────

    // Layer 0: solid surface color fallback
    Rectangle {
        id: solidFallback
        anchors.fill: parent
        color: Colours.palette.m3surface
        z: 0
    }

    // Layer 1: blurred wallpaper image (fades out when live screencopy is ready)
    Image {
        id: wallpaperFallback
        anchors.fill: parent
        source: {
            const path = Wallpapers.current || Config.paths.wallpaper || "";
            if (!path) return "";
            const source = Wallpapers.getColorSource(path);
            return source.startsWith("/") ? "file://" + source : source;
        }
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.screen.width
        sourceSize.height: root.screen.height
        opacity: 1
        z: 1

        visible: (status === Image.Ready || status === Image.Loading) && opacity > 0

        layer.enabled: visible
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }

        onStatusChanged: {
            if (status === Image.Error)
                console.log("Wallpaper failed to load, falling back to solid color");
        }
    }

    // Layer 2: live screen capture with heavy blur
    ScreencopyView {
        id: background

        anchors.fill: parent
        captureSource: root.screen
        opacity: 0
        z: 2

        visible: opacity > 0

        layer.enabled: visible
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: 64
            blurMultiplier: 1
        }
    }

    // Layer 3: subtle dark scrim — deepens blur contrast so the panel pops
    Rectangle {
        id: dimScrim
        anchors.fill: parent
        z: 3
        color: Qt.alpha("#000000", 0.2)
    }

    // ── Optional flanking side panels (showExtras) ─────────────────────────────
    Item {
        id: extrasLayer
        anchors.fill: parent
        z: 4
        visible: Config.lock.showExtras && opacity > 0
        opacity: 0

        ParallelAnimation {
            id: extrasShowAnim
            running: false

            Anim {
                target: extrasLayer
                property: "opacity"
                to: 1
                duration: Appearance.anim.durations.normal
            }
            Anim {
                target: leftPanel
                property: "x"
                from: Appearance.spacing.xxl
                to: 0
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
            Anim {
                target: rightPanel
                property: "x"
                from: -Appearance.spacing.xxl
                to: 0
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        }

        Connections {
            target: initAnim
            function onFinished(): void {
                extrasShowAnim.start();
            }
        }

        // Left extras card (weather + fetch + media)
        StyledRect {
            id: leftPanel

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.horizontalCenter
            anchors.rightMargin: root.panelWidth / 2 + Appearance.spacing.xxl * 2

            width: Math.min(Math.round(300 * root.panelScale), parent.width / 4)
            height: root.panelHeight

            radius: Appearance.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 16
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.4)
            }

            Content {
                anchors.fill: parent
                anchors.margins: 0
                lock: root
                showLeft: true
                showRight: false
            }
        }

        // Right extras card (resources + notifications)
        StyledRect {
            id: rightPanel

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.horizontalCenter
            anchors.leftMargin: root.panelWidth / 2 + Appearance.spacing.xxl * 2

            width: Math.min(Math.round(300 * root.panelScale), parent.width / 4)
            height: root.panelHeight

            radius: Appearance.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 16
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.4)
            }

            Content {
                anchors.fill: parent
                anchors.margins: 0
                lock: root
                showLeft: false
                showRight: true
            }
        }
    }

    // ── Main floating panel ────────────────────────────────────────────────────
    Item {
        id: lockContent

        readonly property int iconSize: lockIcon.implicitHeight + Appearance.padding.xl * 4

        anchors.centerIn: parent
        implicitWidth: iconSize
        implicitHeight: iconSize
        z: 5

        rotation: 180
        scale: 0

        // Frosted glass surface card
        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: Colours.palette.m3surfaceContainer
            radius: lockContent.iconSize / 4 * Appearance.rounding.scale
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 36
                shadowVerticalOffset: 8
                shadowHorizontalOffset: 0
                shadowBlur: 0.7
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.45)
            }
        }

        // Subtle inner border for depth
        Rectangle {
            anchors.fill: parent
            radius: lockBg.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
            z: 1
        }

        // Lock icon shown during spin-up / unlock animation
        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            color: Colours.palette.m3primary
            font.pointSize: Appearance.font.size.headlineLarge * 4
            font.bold: true
            rotation: 180
        }

        // Center content (clock + avatar + password)
        Center {
            id: centerPanel

            anchors.fill: parent
            anchors.margins: Appearance.padding.xl

            lock: root
            opacity: 0
            scale: 0
        }
    }
}
