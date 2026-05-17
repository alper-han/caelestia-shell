pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.bar as Bar
import qs.utils

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness
    readonly property real minThickness: win.contentItem.Config.border.minThickness
    readonly property real visibleBarWidth: bar.shouldBeVisible ? bar.contentWidth : clampedThickness
    readonly property real visibleBarHeight: bar.shouldBeVisible ? bar.contentHeight : clampedThickness
    readonly property real leftInset: BarPosition.isLeft(bar.position) ? visibleBarWidth : clampedThickness
    readonly property real rightInset: BarPosition.isRight(bar.position) ? visibleBarWidth : clampedThickness
    readonly property real topInset: BarPosition.isTop(bar.position) ? visibleBarHeight : clampedThickness
    readonly property real bottomInset: BarPosition.isBottom(bar.position) ? visibleBarHeight : clampedThickness

    function panelExtent(size: real, offsetScale: real): real {
        return Math.max(minThickness, size * (1 - offsetScale));
    }

    x: leftInset + win.dragMaskPadding
    y: topInset + win.dragMaskPadding
    width: win.width - leftInset - rightInset - win.dragMaskPadding * 2
    height: win.height - topInset - bottomInset - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: root.panels.dashboard.offsetScale < 1 ? panel.height * (1 - root.panels.dashboard.offsetScale) + root.borderThickness : 0
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: root.panelExtent(panel.height, root.panels.launcher.offsetScale) + root.win.bottomContentInset
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: root.panelExtent(panel.width, root.panels.session.offsetScale) + root.win.rightContentInset + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: root.panelExtent(panel.width, root.panels.sidebar.offsetScale) + root.win.rightContentInset
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: root.panelExtent(panel.width, root.panels.osd.offsetScale) + root.win.rightContentInset + sessionRegion.width
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + root.win.topContentInset
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: root.panelExtent(panel.height, root.panels.utilities.offsetScale) + root.win.bottomContentInset
    }

    R {
        panel: root.panels.popoutsWrapper
        readonly property bool detached: root.panels.popouts.isDetached
        readonly property bool activePopoutSurface: root.panels.popouts.hasCurrent || detached
        x: root.win.panelWindowX(panel, !detached && BarPosition.isVertical(root.bar.position) ? -panel.width * 0.2 : 0)
        y: root.win.panelWindowY(panel, !detached && BarPosition.isHorizontal(root.bar.position) ? -panel.height * 0.08 : 0)
        width: activePopoutSurface ? panel.width * (!detached && BarPosition.isVertical(root.bar.position) ? 1.2 : 1) : 0
        height: activePopoutSurface ? panel.height * (!detached && BarPosition.isHorizontal(root.bar.position) ? 1.08 : 1) : 0
    }

    component R: Region {
        required property Item panel

        x: root.win.panelWindowX(panel, 0)
        y: root.win.panelWindowY(panel, 0)
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
