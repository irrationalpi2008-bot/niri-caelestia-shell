import qs.components
import qs.config
import QtQuick

Item {
    id: root

    required property bool visibility

    visible: height > 0
    implicitHeight: 0
    implicitWidth: content.implicitWidth

    states: State {
        name: "visible"
        when: root.visibility

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
                duration: Appearance.anim.durations.small
                easing.bezierCurve: Appearance.anim.curves.emphasizedDecel
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.small / 2
                easing.bezierCurve: Appearance.anim.curves.emphasizedAccel
            }
        }
    ]

    property bool wasOpened: false

    onVisibilityChanged: {
        if (root.visibility)
            root.wasOpened = true;
    }

    Loader {
        id: content

        active: root.visibility || root.wasOpened

        anchors.bottom: parent.bottom
        anchors.right: parent.right

        sourceComponent: Content {}
    }
}
