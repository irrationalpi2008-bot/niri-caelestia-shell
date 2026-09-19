import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth
    clip: true

    states: State {
        name: "visible"
        when: root.visibilities.quicktoggles

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
        function onQuicktogglesChanged(): void {
            if (root.visibilities.quicktoggles)
                root.wasOpened = true;
        }
    }

    Loader {
        id: content

        active: root.visibilities.quicktoggles || root.wasOpened

        anchors.bottom: parent.bottom
        anchors.right: parent.right

        sourceComponent: Content {
            wrapper: root
            visibilities: root.visibilities
        }
    }
}
