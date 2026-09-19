import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    required property var panels

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: State {
        name: "visible"
        when: root.visibilities.launcher && Config.launcher.enabled

        PropertyChanges {
            root.implicitHeight: content.implicitHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }
    ]

    property bool wasOpened: false

    Connections {
        target: root.visibilities
        function onLauncherChanged(): void {
            if (root.visibilities.launcher)
                root.wasOpened = true;
        }
    }

    Loader {
        id: content

        active: (root.visibilities.launcher && Config.launcher.enabled) || root.wasOpened

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: Content {
            wrapper: root
            visibilities: root.visibilities
            panels: root.panels
        }
    }
}
