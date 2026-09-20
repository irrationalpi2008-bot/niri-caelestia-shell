pragma ComponentBehavior: Bound

import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.utils

IconImage {
    id: root

    property string colorOverride: ""
    property real brightnessOverride: 0.5
    property real contrastOverride: 1

    smooth: true
    asynchronous: true
    layer.enabled: colorOverride !== ""
    source: SysInfo.osLogo

    layer.effect: MultiEffect {
        colorization: 1
        colorizationColor: root.colorOverride
        brightness: root.brightnessOverride
        contrast: root.contrastOverride
    }
}
