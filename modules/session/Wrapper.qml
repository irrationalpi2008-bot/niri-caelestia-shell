import qs.components
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities

    visible: width > 0
    implicitWidth: 0
    implicitHeight: content.implicitHeight

    states: State {
        name: "visible"
        when: root.visibilities.session && Config.session.enabled

        PropertyChanges {
            root.implicitWidth: content.implicitWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.normal
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitWidth"
                duration: Appearance.anim.durations.small
                easing.bezierCurve: root.visibilities.osd ? Appearance.anim.curves.emphasizedDecel : Appearance.anim.curves.emphasizedAccel
            }
        }
    ]

    property bool wasOpened: false

    Connections {
        target: root.visibilities
        function onSessionChanged(): void {
            if (root.visibilities.session)
                root.wasOpened = true;
        }
    }

    Loader {
        id: content

        active: (root.visibilities.session && Config.session.enabled) || root.wasOpened

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        sourceComponent: Content {
            visibilities: root.visibilities
        }
    }
}
