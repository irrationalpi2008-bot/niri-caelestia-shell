pragma ComponentBehavior: Bound

import qs.components
// import qs.components.effects
import qs.config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property int index
    required property var occupied
    required property int groupOffset
    required property int focusedWindowId
    required property int activeWsId

    required property Item windowPopoutSignal

    readonly property bool isWorkspace: true // Flag for finding workspace children
    readonly property int size: isWorkspace ? implicitHeight + (hasWindows ? Appearance.padding.xs : 0) : 0
    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    // To make the windows repopulate, for Niri.
    // onGroupOffsetChanged: {
    //     windows.active = false;
    //     windows.active = true;
    // }

    // clip: true

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    Layout.alignment: Qt.AlignLeft
    Layout.preferredHeight: size

    spacing: 0

    WorkspaceIcon {
        workspace: root
    }

    Loader {
        id: windows

        Layout.alignment: Qt.AlignCenter
        // Layout.fillHeight: true
        Layout.topMargin: -Config.bar.sizes.innerWidth / 10

        visible: active
        active: root.hasWindows
        asynchronous: true

        sourceComponent: DraggableWindowColumn {
            id: dragDropLayout
            spacing: 0

            workspace: root
            focusedWindowId: root.focusedWindowId
            activeWsId: root.activeWsId
            ws: root.ws
            windowPopoutSignal: root.windowPopoutSignal
            idx: root.index
            groupOffset: root.groupOffset
        }
    }
}
