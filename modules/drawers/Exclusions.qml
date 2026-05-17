pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.modules.bar as Bar
import qs.utils

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar

    ExclusionZone {
        anchors.left: true
        exclusiveZone: BarPosition.isLeft(root.bar.position) ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: BarPosition.isTop(root.bar.position) ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: BarPosition.isRight(root.bar.position) ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: BarPosition.isBottom(root.bar.position) ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
