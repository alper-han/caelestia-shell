pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.utils
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness
    readonly property real visibleBarWidth: bar.shouldBeVisible ? bar.contentWidth : root.borderThickness
    readonly property real visibleBarHeight: bar.shouldBeVisible ? bar.contentHeight : root.borderThickness
    readonly property real leftContentInset: BarPosition.isLeft(bar.position) ? visibleBarWidth : root.borderThickness
    readonly property real rightContentInset: BarPosition.isRight(bar.position) ? visibleBarWidth : root.borderThickness
    readonly property real topContentInset: BarPosition.isTop(bar.position) ? visibleBarHeight : root.borderThickness
    readonly property real bottomContentInset: BarPosition.isBottom(bar.position) ? visibleBarHeight : root.borderThickness

    function panelWindowX(panel: Item, localX: real): real {
        return root.leftContentInset + panel.x + localX;
    }

    function panelWindowY(panel: Item, localY: real): real {
        return root.topContentInset + panel.y + localY;
    }

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || (monitor?.activeWorkspace?.lastIpcObject.windows ?? 0) > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session", "sidebar"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return Math.max(...thresholds);
    }

    onHasFullscreenChanged: {
        visibilities.launcher = false;
        visibilities.session = false;
        visibilities.dashboard = false;
        panels.popouts.close();
    }

    readonly property bool barShowOnHover: contentItem.Config.bar.showOnHover
    readonly property bool launcherEnabled: contentItem.Config.launcher.enabled
    readonly property bool launcherShowOnHover: contentItem.Config.launcher.showOnHover
    readonly property bool dashboardEnabled: contentItem.Config.dashboard.enabled
    readonly property bool dashboardShowOnHover: contentItem.Config.dashboard.showOnHover

    function resetBarState(): void {
        bar.isHovered = false;
        panels.popouts.close();
        bar.closeTray();
    }

    function resetLauncherState(): void {
        visibilities.launcher = false;
        panels.popouts.close();
        bar.closeTray();
    }

    function resetDashboardState(): void {
        visibilities.dashboard = false;
        interactions.dashboardShortcutActive = false;
        panels.popouts.close();
        bar.closeTray();
    }

    onBarShowOnHoverChanged: {
        if (!barShowOnHover)
            resetBarState();
    }

    onLauncherEnabledChanged: {
        if (!launcherEnabled)
            resetLauncherState();
    }

    onLauncherShowOnHoverChanged: resetLauncherState()

    onDashboardEnabledChanged: {
        if (!dashboardEnabled)
            resetDashboardState();
    }

    onDashboardShowOnHoverChanged: resetDashboardState()

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || panels.dashboard.needsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: hasFullscreen ? emptyRegion : regions

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Region {
        id: emptyRegion

        x: root.panelWindowX(panels.notifications, 0)
        y: root.panelWindowY(panels.notifications, 0)
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: root.panelWindowX(panels.osdWrapper, panels.osd.x)
            y: root.panelWindowY(panels.osdWrapper, panels.osd.y)
            width: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + root.borderThickness
            height: panels.osd.height
        }
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: (visibilities.launcher && root.contentItem.Config.launcher.enabled) || (visibilities.session && root.contentItem.Config.session.enabled) || (visibilities.sidebar && root.contentItem.Config.sidebar.enabled) || (!root.contentItem.Config.dashboard.showOnHover && visibilities.dashboard && root.contentItem.Config.dashboard.enabled) || (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
        windows: [root]
        onCleared: {
            visibilities.launcher = false;
            visibilities.session = false;
            visibilities.sidebar = false;
            visibilities.dashboard = false;
            panels.popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {}
        }
    }

    Item {
        anchors.fill: parent
        opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: Colours.palette.m3surface
            smoothing: root.contentItem.Config.border.smoothing

            Behavior on color {
                CAnim {}
            }
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: root.leftContentInset - anchors.margins - root.sdfBorderOffset
            borderRight: root.rightContentInset - anchors.margins - root.sdfBorderOffset
            borderTop: root.topContentInset - anchors.margins - root.sdfBorderOffset
            borderBottom: root.bottomContentInset - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: dashBg

            readonly property bool activeSurface: panels.dashboard.offsetScale < 1

            group: activeSurface ? blobGroup : null
            panel: panels.dashboard
            deformAmount: 0.1
            implicitHeight: activeSurface ? panel.height : 0
        }

        PanelBg {
            id: launcherBg

            panel: panels.launcher
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg

            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: root.panelWindowX(panels.sessionWrapper, panels.session.x)
            implicitWidth: panels.session.width
        }

        PanelBg {
            id: sidebarBg

            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            bottomLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: osdBg

            panel: panels.osdWrapper
            deformAmount: 0.25
            x: root.panelWindowX(panels.osdWrapper, panels.osd.x)
            implicitWidth: panels.osd.width
        }

        PanelBg {
            id: notifsBg

            panel: panels.notifications
        }

        PanelBg {
            id: utilsBg

            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: popoutBg

            // Extra size to prevent movement deformation partially detaching panel from bar
            readonly property bool activePopoutSurface: panels.popouts.hasCurrent || panels.popouts.isDetached
            readonly property real popoutWidth: activePopoutSurface ? panels.popouts.nonAnimWidth : 0
            readonly property real popoutHeight: activePopoutSurface ? panels.popouts.nonAnimHeight : 0
            readonly property bool rightAttached: !panels.popouts.isDetached && BarPosition.isRight(bar.position)
            readonly property bool bottomAttached: !panels.popouts.isDetached && BarPosition.isBottom(bar.position)
            readonly property real surfaceWidth: popoutWidth
            readonly property real surfaceHeight: popoutHeight
            property bool popoutVertical: BarPosition.isVertical(bar.position)
            property real extraWidth: panels.popouts.isDetached || !popoutVertical ? 0 : 0.2
            property real extraHeight: panels.popouts.isDetached || popoutVertical ? 0 : 0.08
            property real extraX: BarPosition.isLeft(bar.position) ? popoutWidth * extraWidth : rightAttached ? surfaceWidth * extraWidth : 0
            property real extraY: BarPosition.isTop(bar.position) ? popoutHeight * extraHeight : bottomAttached ? surfaceHeight * extraHeight : 0

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            x: root.panelWindowX(panels.popoutsWrapper, 0) - extraX
            y: root.panelWindowY(panels.popoutsWrapper, 0) - extraY
            implicitWidth: surfaceWidth + extraX
            implicitHeight: surfaceHeight + extraY

            Behavior on extraWidth {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }

            Behavior on extraHeight {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
        }
    }

    DrawerVisibilities {
        id: visibilities

        Component.onCompleted: Visibilities.load(root.screen, this)
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        visibilities: visibilities
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            visibilities: visibilities
            bar: bar
            borderThickness: root.borderThickness

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            screen: root.screen
            visibilities: visibilities
            popouts: panels.popouts

            fullscreen: root.hasFullscreen

            Component.onCompleted: Visibilities.bars.set(root.screen, this)
        }
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15

        group: blobGroup
        x: root.panelWindowX(panel, 0)
        y: root.panelWindowY(panel, 0)
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.large
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
