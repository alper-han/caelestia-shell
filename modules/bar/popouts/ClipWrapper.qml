pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others
import qs.utils

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness
    required property string position

    readonly property alias content: content
    readonly property bool isVertical: BarPosition.isVertical(position)
    property real offsetScale: content.hasCurrent || content.isDetached ? 0 : 1

    function centeredMainOffset(size: real, maxSize: real): real {
        if (size >= maxSize)
            return 0;

        const off = content.currentCenter - borderThickness - size / 2;
        const diff = maxSize - Math.floor(off + size);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    signal attachedClosed()

    function closeAttached(): void {
        if (!content.isDetached) {
            content.close();
            attachedClosed();
        }
    }

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: content.implicitWidth * (!content.isDetached && isVertical ? 1 - offsetScale : 1)
    implicitHeight: content.implicitHeight * (!content.isDetached && !isVertical ? 1 - offsetScale : 1)
    width: implicitWidth
    height: implicitHeight

    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        if (isVertical)
            return BarPosition.isRight(position) ? parent.width - content.nonAnimWidth : 0;
        return centeredMainOffset(content.nonAnimWidth, parent.width);
    }
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (!isVertical)
            return BarPosition.isBottom(position) ? parent.height - content.nonAnimHeight : 0;
        return centeredMainOffset(content.nonAnimHeight, parent.height);
    }

    readonly property bool trayCompact: Config.bar.tray.compact
    readonly property bool trayBackground: Config.bar.tray.background
    readonly property bool activeWindowCompact: Config.bar.activeWindow.compact
    readonly property bool activeWindowInverted: Config.bar.activeWindow.inverted
    readonly property bool activeWindowPopout: Config.bar.popouts.activeWindow
    readonly property bool statusIconsPopout: Config.bar.popouts.statusIcons
    readonly property bool trayPopout: Config.bar.popouts.tray
    readonly property var entries: Config.bar.entries
    readonly property var status: Config.bar.status

    onPositionChanged: closeAttached()
    onTrayCompactChanged: closeAttached()
    onTrayBackgroundChanged: closeAttached()
    onActiveWindowCompactChanged: closeAttached()
    onActiveWindowInvertedChanged: closeAttached()
    onActiveWindowPopoutChanged: closeAttached()
    onStatusIconsPopoutChanged: closeAttached()
    onTrayPopoutChanged: closeAttached()
    onEntriesChanged: closeAttached()
    onStatusChanged: closeAttached()

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on x {
        enabled: content.isDetached || !BarPosition.isRight(root.position)

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: root.offsetScale < 1 && (content.isDetached || !BarPosition.isBottom(root.position))

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        x: {
            if (content.isDetached)
                return 0;
            if (BarPosition.isLeft(root.position))
                return -(implicitWidth + 5) * root.offsetScale;
            if (BarPosition.isRight(root.position))
                return root.width - implicitWidth + (implicitWidth + 5) * root.offsetScale;
            return (root.width - implicitWidth) / 2;
        }
        y: {
            if (content.isDetached)
                return 0;
            if (BarPosition.isTop(root.position))
                return -(implicitHeight + 5) * root.offsetScale;
            if (BarPosition.isBottom(root.position))
                return root.height - implicitHeight + (implicitHeight + 5) * root.offsetScale;
            return (root.height - implicitHeight) / 2;
        }
    }
}
