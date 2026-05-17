import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.bar as Bar
import qs.modules.bar.popouts as BarPopouts
import qs.utils

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.Wrapper popouts
    required property DrawerVisibilities visibilities
    required property Panels panels
    required property Bar.BarWrapper bar
    required property real borderThickness
    required property bool fullscreen

    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool utilitiesShortcutActive

    readonly property real barThickness: bar.contentThickness
    readonly property real barVisualThickness: bar.isVertical ? bar.implicitWidth : bar.implicitHeight
    readonly property real visibleBarWidth: bar.shouldBeVisible ? bar.contentWidth : borderThickness
    readonly property real visibleBarHeight: bar.shouldBeVisible ? bar.contentHeight : borderThickness
    readonly property real leftContentInset: BarPosition.isLeft(bar.position) ? visibleBarWidth : borderThickness
    readonly property real rightContentInset: BarPosition.isRight(bar.position) ? visibleBarWidth : borderThickness
    readonly property real topContentInset: BarPosition.isTop(bar.position) ? visibleBarHeight : borderThickness
    readonly property real bottomContentInset: BarPosition.isBottom(bar.position) ? visibleBarHeight : borderThickness

    function panelWindowX(panel: Item, localX: real): real {
        return leftContentInset + panel.x + localX;
    }

    function panelWindowY(panel: Item, localY: real): real {
        return topContentInset + panel.y + localY;
    }

    function barMainCoord(x: real, y: real): real {
        return BarPosition.mainCoord(bar.position, x, y);
    }

    function isInBarEdge(x: real, y: real, thickness: real): bool {
        return BarPosition.isInEdgeArea(bar.position, x, y, width, height, thickness);
    }

    function barDragDelta(dragX: real, dragY: real): real {
        return bar.isVertical ? dragX : dragY;
    }

    function showDragDelta(dragX: real, dragY: real): real {
        const delta = barDragDelta(dragX, dragY);
        return BarPosition.isLeft(bar.position) || BarPosition.isTop(bar.position) ? delta : -delta;
    }

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = panelWindowY(panel, 0);
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = panelWindowX(panel, 0);
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        return x < panelWindowX(panel, panel.width) && withinPanelHeight(panel, x, y);
    }

    function inPanelRect(panel: Item, x: real, y: real): bool {
        const panelX = panelWindowX(panel, 0);
        const panelY = panelWindowY(panel, 0);
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding && y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function inExpandedPopoutRect(x: real, y: real): bool {
        const panel = panels.popoutsWrapper;
        const detached = popouts.isDetached;
        const active = popouts.hasCurrent || detached;

        if (!active)
            return false;

        let panelX = panelWindowX(panel, 0);
        let panelY = panelWindowY(panel, 0);
        let panelWidth = panel.width;
        let panelHeight = panel.height;

        if (!detached && BarPosition.isVertical(bar.position)) {
            const extraWidth = panelWidth * 0.2;
            panelWidth += extraWidth;
            if (BarPosition.isLeft(bar.position))
                panelX -= extraWidth;
        } else if (!detached && BarPosition.isHorizontal(bar.position)) {
            const extraHeight = panelHeight * 0.08;
            panelHeight += extraHeight;
            if (BarPosition.isHorizontal(bar.position))
                panelY -= extraHeight;
        }

        return x >= panelX - Config.border.rounding && x <= panelX + panelWidth + Config.border.rounding && y >= panelY - Config.border.rounding && y <= panelY + panelHeight + Config.border.rounding;
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > Math.min(width - Config.border.minThickness, panelWindowX(panel, 0)) && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        const panelBottom = panelWindowY(panel, 0) + Math.max(Config.border.minThickness, panelHeight);
        return y < Math.max(topContentInset + Config.border.minThickness, panelBottom) && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel: Item, x: real, y: real, isCorner = false): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y > height - bottomContentInset - Math.max(Config.border.minThickness, panelHeight) - (isCorner ? Config.border.rounding : 0) && withinPanelWidth(panel, x, y);
    }

    function onWheel(event: WheelEvent): void {
        if (fullscreen)
            return;
        if (isInBarEdge(event.x, event.y, barVisualThickness)) {
            bar.handleWheel(event.x, event.y, event.angleDelta);
        }
    }

    function canAutoClosePopout(): bool {
        return !popouts.isDetached && (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1);
    }

    function requestPopoutClose(): void {
        if (canAutoClosePopout() && !popoutCloseTimer.running)
            popoutCloseTimer.start();
    }

    function cancelPopoutClose(): void {
        popoutCloseTimer.stop();
    }

    function closePopoutsIfStillOutside(): void {
        if (!canAutoClosePopout())
            return;

        if (containsMouse) {
            if (isInBarEdge(mouseX, mouseY, barVisualThickness)) {
                if (bar.checkPopout(mouseX, mouseY))
                    return;
            } else if (inExpandedPopoutRect(mouseX, mouseY)) {
                return;
            }
        }

        popouts.hasCurrent = false;
        bar.closeTray();
    }

    Timer {
        id: popoutCloseTimer

        interval: 180
        repeat: false
        onTriggered: root.closePopoutsIfStillOutside()
    }

    Connections {
        function onPositionChanged(): void {
            popoutCloseTimer.stop();
            dashboardShortcutActive = false;
            osdShortcutActive = false;
            utilitiesShortcutActive = false;
            popouts.close();
            bar.closeTray();
            bar.isHovered = false;
        }

        target: root.bar
    }

    anchors.fill: parent
    acceptedButtons: fullscreen ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    onPressed: event => dragStart = Qt.point(event.x, event.y)
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                visibilities.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!dashboardShortcutActive)
                visibilities.dashboard = false;

            if (!utilitiesShortcutActive)
                visibilities.utilities = false;

            requestPopoutClose();

            if (Config.bar.showOnHover)
                bar.isHovered = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached)
            return;

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            root.panels.osd.hovered = inRightPanel(panels.osdWrapper, x, y);
            return;
        }

        // Show bar in non-exclusive mode on hover
        if (!visibilities.bar && Config.bar.showOnHover && isInBarEdge(x, y, barThickness))
            bar.isHovered = true;

        // Show/hide bar on drag
        if (pressed && isInBarEdge(dragStart.x, dragStart.y, barThickness)) {
            const barDrag = showDragDelta(dragX, dragY);
            if (barDrag > Config.bar.dragThreshold)
                visibilities.bar = true;
            else if (barDrag < -Config.bar.dragThreshold)
                visibilities.bar = false;
        }

        if (panels.sidebar.offsetScale === 1) {
            // Show osd on hover
            const showOsd = inRightPanel(panels.osdWrapper, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                visibilities.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            const showSidebar = pressed && dragStart.x > Math.min(width - Config.border.minThickness, panelWindowX(panels.sidebar, 0));

            // Show/hide session on drag
            if (pressed && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    visibilities.session = true;
                else if (dragX > Config.session.dragThreshold)
                    visibilities.session = false;

                // Show sidebar on drag if in session area and session is nearly fully visible
                if (showSidebar && panels.session.offsetScale <= 0 && dragX < -Config.sidebar.dragThreshold)
                    visibilities.sidebar = true;
            } else if (showSidebar && dragX < -Config.sidebar.dragThreshold) {
                // Show sidebar on drag if not in session area
                visibilities.sidebar = true;
            }
        } else {
            const outOfSidebar = x < panelWindowX(panels.sidebar, 0);
            // Show osd on hover
            const showOsd = outOfSidebar && inRightPanel(panels.osdWrapper, x, y);

            // Always update visibility based on hover if not in shortcut mode
            if (!osdShortcutActive) {
                visibilities.osd = showOsd;
                root.panels.osd.hovered = showOsd;
            } else if (showOsd) {
                // If hovering over OSD area while in shortcut mode, transition to hover control
                osdShortcutActive = false;
                root.panels.osd.hovered = true;
            }

            // Show/hide session on drag
            if (pressed && outOfSidebar && inRightPanel(panels.sessionWrapper, dragStart.x, dragStart.y) && withinPanelHeight(panels.sessionWrapper, x, y)) {
                if (dragX < -Config.session.dragThreshold)
                    visibilities.session = true;
                else if (dragX > Config.session.dragThreshold)
                    visibilities.session = false;
            }

            // Hide sidebar on drag
            if (pressed && inRightPanel(panels.sidebar, dragStart.x, dragStart.y) && dragX > Config.sidebar.dragThreshold)
                visibilities.sidebar = false;
        }

        // Show launcher on hover, or show/hide on drag if hover is disabled
        if (Config.launcher.showOnHover) {
            if (!visibilities.launcher && inBottomPanel(panels.launcher, x, y))
                visibilities.launcher = true;
        } else if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                visibilities.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                visibilities.launcher = false;
        }

        // Show dashboard on hover
        const showDashboard = Config.dashboard.showOnHover && inTopPanel(panels.dashboard, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!dashboardShortcutActive) {
            visibilities.dashboard = showDashboard;
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (pressed && inTopPanel(panels.dashboard, dragStart.x, dragStart.y) && withinPanelWidth(panels.dashboard, x, y)) {
            if (dragY > Config.dashboard.dragThreshold)
                visibilities.dashboard = true;
            else if (dragY < -Config.dashboard.dragThreshold)
                visibilities.dashboard = false;
        }

        // Show utilities on hover
        const showUtilities = inBottomPanel(panels.utilities, x, y, true);

        // Always update visibility based on hover if not in shortcut mode
        if (!utilitiesShortcutActive) {
            visibilities.utilities = showUtilities;
        } else if (showUtilities) {
            // If hovering over utilities area while in shortcut mode, transition to hover control
            utilitiesShortcutActive = false;
        }

        // Show popouts on hover
        if (isInBarEdge(x, y, barVisualThickness)) {
            if (bar.checkPopout(x, y))
                cancelPopoutClose();
            else
                requestPopoutClose();
        } else if (inExpandedPopoutRect(x, y)) {
            cancelPopoutClose();
        } else {
            requestPopoutClose();
        }
    }

    // Monitor individual visibility changes
    Connections {
        function onLauncherChanged() {
            // If launcher is hidden, clear shortcut flags for dashboard and OSD
            if (!root.visibilities.launcher) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;
                root.utilitiesShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);

                if (!inDashboardArea) {
                    root.visibilities.dashboard = false;
                }
                if (!inOsdArea) {
                    root.visibilities.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onDashboardChanged() {
            if (root.visibilities.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.visibilities.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        function onUtilitiesChanged() {
            if (root.visibilities.utilities) {
                // Utilities became visible, immediately check if this should be shortcut mode
                const inUtilitiesArea = root.inBottomPanel(root.panels.utilities, root.mouseX, root.mouseY);
                if (!inUtilitiesArea) {
                    root.utilitiesShortcutActive = true;
                }
            } else {
                // Utilities hidden, clear shortcut flag
                root.utilitiesShortcutActive = false;
            }
        }

        target: root.visibilities
    }
}
