pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.components.widgets
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    required property var wrapper
    required property PersistentProperties visibilities

    readonly property int padding: Math.max(Appearance.padding.xl, Config.border.rounding)

    implicitWidth: 450
    implicitHeight: mainLayout.implicitHeight + padding * 2

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding
        spacing: Appearance.spacing.sm

        /* ─── NOTIFICATIONS ─── */
        StyledClippingRect {
            id: notifSection
            Layout.fillWidth: true
            Layout.preferredHeight: notifExpanded ? expandedHeight : collapsedHeight
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            readonly property bool notifExpanded: root.visibilities.notifsExpanded
            readonly property int collapsedHeight: notifListWidget.showHeader ? 52 : 0
            readonly property int screenHalfHeight: (Screen.height || 1080) / 2
            readonly property int desiredHeight: notifListWidget.desiredContentHeight + Appearance.padding.md * 2
            readonly property int expandedHeight: Notifs.list.length === 0
                ? collapsedHeight + 120
                : Math.max(collapsedHeight + 120, Math.min(desiredHeight, screenHalfHeight))

            // Tracks whether the user manually collapsed the panel while notifications exist.
            // Reset to false when the notification list empties, so the next incoming
            // notification triggers an auto-expand again.
            property bool userCollapsed: false
            property int notifCount: Notifs.list.length

            onNotifCountChanged: {
                if (notifCount === 0) {
                    userCollapsed = false;
                    root.visibilities.notifsExpanded = false;
                    notifListWidget.expanded = false;
                } else if (!userCollapsed) {
                    root.visibilities.notifsExpanded = true;
                    notifListWidget.expanded = true;
                }
            }

            Component.onCompleted: {
                if (Notifs.list.length > 0)
                    root.visibilities.notifsExpanded = true;
            }

            Behavior on Layout.preferredHeight {
                enabled: Boolean(root.wrapper && root.wrapper.visible && root.wrapper.height >= root.wrapper.implicitHeight - 1)
                Anim {
                    duration: Appearance.anim.durations.normal
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }

            NotificationList {
                id: notifListWidget
                anchors.fill: parent
                anchors.margins: Appearance.padding.md
                expanded: notifSection.notifExpanded
                expandable: true

                Connections {
                    target: notifListWidget
                    function onExpandedChanged(): void {
                        root.visibilities.notifsExpanded = notifListWidget.expanded;
                        if (!notifListWidget.expanded && Notifs.list.length > 0)
                            notifSection.userCollapsed = true;
                        else if (notifListWidget.expanded)
                            notifSection.userCollapsed = false;
                    }
                    function onCleared(): void {
                        notifSection.userCollapsed = false;
                        root.visibilities.notifsExpanded = false;
                        notifListWidget.expanded = false;
                    }
                }
            }
        }

        /* ─── QUICK TOGGLES ─── */
        StyledRect {
            id: togglesSection
            Layout.fillWidth: true
            implicitHeight: togglesRow.implicitHeight + Appearance.padding.md * 2
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: togglesRow
                anchors.fill: parent
                anchors.margins: Appearance.padding.md
                spacing: Appearance.spacing.sm

                Toggle {
                    icon: "wifi"
                    checked: Network.wifiEnabled
                    onClicked: Network.toggleWifi()
                }

                Toggle {
                    icon: "bluetooth"
                    checked: Bluetooth.defaultAdapter?.enabled ?? false
                    onClicked: {
                        const adapter = Bluetooth.defaultAdapter;
                        if (adapter)
                            adapter.enabled = !adapter.enabled;
                    }
                }

                Toggle {
                    icon: "mic"
                    checked: !Audio.sourceMuted
                    onClicked: {
                        const audio = Audio.source?.audio;
                        if (audio)
                            audio.muted = !audio.muted;
                    }
                }

                Toggle {
                    icon: "vpn_key"
                    checked: VPN.connected
                    enabled: !VPN.connecting
                    visible: Config.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false)
                    onClicked: VPN.toggle()
                }

                Toggle {
                    icon: "settings"
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    toggle: false
                    onClicked: {
                        root.visibilities.quicktoggles = false;
                        openControlCenter("network");
                    }
                }
            }
        }

    }

    function openControlCenter(pane: string): void {
        const panelsPopouts = root.wrapper && root.wrapper.parent ? root.wrapper.parent.popouts : null;
        if (panelsPopouts) {
            panelsPopouts.detach(pane);
        }
        // Close the quicktoggles panel after opening the ControlCenter popout
        if (root.visibilities) {
            root.visibilities.quicktoggles = false;
        }
    }

    // Toggle component matching Hyprland's utilities/cards/Toggles style
    component Toggle: IconButton {
        Layout.fillWidth: true
        Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Appearance.padding.xl : internalChecked ? Appearance.padding.sm : 0)
        radius: stateLayer.pressed ? Appearance.rounding.small / 2 : internalChecked ? Appearance.rounding.small : Appearance.rounding.normal
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        toggle: true
        radiusAnim.duration: Appearance.anim.durations.expressiveFastSpatial
        radiusAnim.easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial

        Behavior on Layout.preferredWidth {
            Anim {
                duration: Appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveFastSpatial
            }
        }
    }

}
