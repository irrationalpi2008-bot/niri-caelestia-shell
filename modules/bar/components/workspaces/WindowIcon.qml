pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick
import Quickshell.Widgets
import "context"

Item {
    id: iconItem

    required property Item workspace
    required property var windowData
    required property var groupWindowData
    required property int wsWindowCount
    required property int windowCount
    required property bool isFocused
    required property bool isWsFocused
    required property int curWindowIndex

    property bool useImageIcon: Config.bar.workspaces.windowIconImage
    property bool groupIconsByApp: Config.bar.workspaces.groupIconsByApp

    property int currentGroupIndex: 0

    property bool popupActive: (Niri.wsContextAnchor === iconItem) || (Niri.wsContextAnchor === workspace) || (Niri.wsContextType === "workspaces")

    // --- Drag Properties ---
    property bool dragActive: false
    property point startPos
    property real dragThreshold: 8
    property int dropTargetIndex: -1

    signal requestPopup(var groupWindowData, var iconItem)
    signal dragStart(var iconItem)
    signal dragUpdate(var iconItem, real mouseY, real mouseX)
    signal dragEnd(var iconItem)

    anchors.left: parent.left

    implicitWidth: iconLoader.implicitWidth + (popupActive ? Config.bar.workspaces.windowContextWidth : 0)
    implicitHeight: iconLoader.implicitHeight

    z: popupActive ? 90 : 0

    Behavior on implicitWidth {
        Anim {
            easing.bezierCurve: Appearance.anim.curves.emphasized
        }
    }

    Loader {
        id: contextLoader
        anchors.left: parent.left
        anchors.leftMargin: iconLoader.implicitWidth + Appearance.padding.xs
        anchors.verticalCenter: parent.verticalCenter
        active: popupActive && Config.bar.workspaces.windowRighClickContext && (Niri.wsContextType !== "none")
        sourceComponent: WindowIconContext {
            iconObj: iconItem
        }
    }

    Loader {
        id: iconLoader

        // anchors.centerIn: parent
        anchors.left: parent.left

        // anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: iconItem.useImageIcon ? imageIconComp : materialIconComp
        property var windowData: iconItem.windowData
        property var windowCount: iconItem.windowCount
        // anchors.margins: Appearance.padding.xs
    }

    Component {
        id: imageIconComp
        StyledRect {
            anchors.centerIn: parent

            implicitHeight: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap
            implicitWidth: Config.bar.workspaces.windowIconSize
            color: "transparent"
            radius: Appearance.rounding.small / 2

            IconImage {
                anchors.centerIn: parent
                property var windowData: iconItem.windowData
                property int windowCount: iconItem.windowCount
                implicitSize: (iconItem.isFocused && iconItem.isWsFocused) ? Config.bar.workspaces.windowIconSize : Config.bar.workspaces.windowIconSize - Appearance.padding.xs
                source: Icons.getAppIcon(windowData.app_id ?? "", "image-missing")
                Behavior on implicitSize {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                WindowGroupBadge {}
            }
        }
    }

    Component {
        id: materialIconComp
        StyledRect {
            anchors.centerIn: parent

            implicitHeight: Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap
            implicitWidth: Config.bar.workspaces.windowIconSize

            MaterialIcon {
                anchors.centerIn: parent
                property var windowData: iconItem.windowData
                property int windowCount: iconItem.windowCount
                font.pointSize: ((iconItem.isFocused && iconItem.isWsFocused)) ? Config.bar.workspaces.windowIconSize - Appearance.padding.xs : Config.bar.workspaces.windowIconSize - Appearance.padding.xs * 2
                grade: 0
                text: Icons.getAppCategoryIcon(windowData.app_id, "help_center")
                color: (iconItem.isWsFocused ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant)
                Behavior on font.pointSize {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                WindowGroupBadge {}
            }
        }
    }

    property alias dgprw: dragPreview

    StyledRect {
        id: dragPreview
        visible: false
        z: 999
        width: iconLoader.width + Appearance.padding.xs
        height: iconLoader.height + Appearance.padding.xs

        color: iconItem.isWsFocused ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.small / 2

        MouseArea {
            anchors.fill: parent
            enabled: true
            cursorShape: Qt.ClosedHandCursor
        }

        // We reuse the same loader as the original icon for preview
        Loader {
            id: dragLoader
            anchors.centerIn: parent
            sourceComponent: iconItem.useImageIcon ? imageIconComp : materialIconComp
            asynchronous: true
        }
    }

    Interaction {
        id: interactionArea
    }

    // --------------------------
    // Interaction / Drag Handling
    // --------------------------
    component Interaction: StateLayer {
        id: mouseArea
        anchors.fill: iconItem
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: (iconItem.dragActive ? Qt.ClosedHandCursor : (Qt.PointingHandCursor))
        pressAndHoldInterval: Appearance.anim.durations.small

        radius: Appearance.rounding.small

        hoverEnabled: true

        onPressAndHold: mouse => {
            iconItem.startPos = Qt.point(mouse.x, mouse.y);
            iconItem.dragActive = true;
        }

        onPositionChanged: mouse => {
            if (pressed && iconItem.dragActive) {
                let distance = Math.sqrt(Math.pow(mouse.x - iconItem.startPos.x, 2) + Math.pow(mouse.y - iconItem.startPos.y, 2));
                if (distance > iconItem.dragThreshold) {
                    iconItem.dragActive = true;
                    iconItem.dragStart(iconItem);
                }
            }
            if (iconItem.dragActive) {
                iconItem.dragUpdate(iconItem, mouse.y, mouse.x);
            }
        }

        onReleased: mouse => {
            if (iconItem.dragActive) {
                iconItem.dragEnd(iconItem);
                iconItem.dragActive = false;
            }
        }

        onCanceled: {
            if (iconItem.dragActive) {
                iconItem.dragEnd(iconItem);
                iconItem.dragActive = false;
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && !iconItem.dragActive) {
                // cycle through group windows or focus single window
                if (Number(Niri.focusedWindowId) !== Number(iconItem.windowData.id)) {
                    Niri.focusWindow(iconItem.windowData.id);
                } else if (iconItem.groupIconsByApp && iconItem.windowCount > 1) {
                    let idx = iconItem.groupWindowData.findIndex(w => w.id === iconItem.windowData.id);
                    if (idx === -1)
                        idx = 0;
                    let nextIdx = (idx + 1) % iconItem.groupWindowData.length;
                    iconItem.currentGroupIndex = nextIdx;
                    iconItem.windowData = iconItem.groupWindowData[nextIdx];
                    Niri.focusWindow(iconItem.windowData.id);
                } else if (iconItem.windowData?.id) {
                    Niri.focusWindow(iconItem.windowData.id);
                }
            } else if (mouse.button === Qt.RightButton) {
                if (!(Niri.wsContextAnchor === iconItem)) {
                    Niri.wsContextAnchor = iconItem;
                    Niri.wsContextType = "item";
                } else {
                    Niri.wsContextAnchor = iconItem.workspace;
                    Niri.wsContextType = "workspace";
                }
                iconItem.requestPopup(iconItem.groupWindowData, iconItem);
            }
        }
    }

    // --------------------------
    // WindowGroupBadge component
    // --------------------------
    component WindowGroupBadge: Loader {
        id: badgeLoader
        active: iconItem.groupIconsByApp

        function calculateMargins() {
            if (iconItem.popupActive && Niri.wsContextType === "item")
                return {
                    right: -Appearance.padding.xl,
                    bottom: (iconLoader.implicitHeight - badgeLoader.height) / 2 - (!iconItem.isFocused ? Appearance.padding.xs / 2 : Config.bar.workspaces.windowIconGap),
                    size: Appearance.padding.xl
                };
            else if (iconItem.isFocused)
                return {
                    right: 0,
                    bottom: 0,
                    size: Appearance.padding.lg
                };
            return {
                right: -Appearance.padding.xs / 2,
                bottom: -Appearance.padding.xs / 2,
                size: Appearance.padding.lg
            };
        }

        anchors {
            bottom: parent.bottom
            right: parent.right
            rightMargin: calculateMargins().right
            bottomMargin: calculateMargins().bottom

            Behavior on rightMargin {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
            Behavior on bottomMargin {
                Anim {
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }

        sourceComponent: Rectangle {
            visible: (iconItem.windowCount > 1)
            color: iconItem.isWsFocused ? (Colours.palette.m3tertiary) : Colours.palette.m3tertiaryContainer
            anchors.centerIn: parent
            radius: Appearance.rounding.small
            width: badgeLoader.calculateMargins().size
            height: badgeLoader.calculateMargins().size

            StyledText {
                animate: true
                anchors.centerIn: parent
                text: iconItem.windowCount
                font.family: Appearance.font.family.mono
                color: iconItem.isWsFocused ? Colours.palette.m3onTertiary : Colours.palette.m3onTertiaryContainer
                font.pointSize: badgeLoader.calculateMargins().size - 3
            }
        }
    }
}
