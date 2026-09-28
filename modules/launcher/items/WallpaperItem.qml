import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.config
import Caelestia.Models
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

Item {
    id: root

    required property FileSystemEntry modelData
    required property PersistentProperties visibilities

    readonly property bool isVideo: Wallpapers.isPathVideo(modelData.path)

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Appearance.padding.lg * 2
    implicitHeight: image.height + label.height + Appearance.spacing.sm / 2 + Appearance.padding.xl + Appearance.padding.md

    StateLayer {
        radius: Appearance.rounding.normal

        function onClicked(): void {
            Wallpapers.setWallpaper(root.modelData.path);
            root.visibilities.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {}
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Appearance.padding.xl
        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.normal

        implicitWidth: Config.launcher.sizes.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: root.isVideo ? "movie" : "image"
            color: Colours.tPalette.m3outline
            font.pointSize: Appearance.font.size.headlineLarge * 2
            font.weight: 600
        }

        CachingImage {
            path: Wallpapers.getColorSource(root.modelData.path)
            smooth: !root.PathView.view.moving
            sourceSize.width: image.implicitWidth * 2
            sourceSize.height: image.implicitHeight * 2

            anchors.fill: parent
        }

        // Play symbol overlay for videos
        MaterialIcon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: font.pointSize * 0.1 // Adjust for play icon visual centering
            text: "play_arrow"
            color: "white"
            font.pointSize: Appearance.font.size.headlineLarge * 2
            visible: root.isVideo

            layer.enabled: root.isVideo
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.alpha("black", 0.5)
                blurMax: 12
            }
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Appearance.spacing.sm / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Appearance.padding.md * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        font.pointSize: Appearance.font.size.bodyMedium
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }
}
