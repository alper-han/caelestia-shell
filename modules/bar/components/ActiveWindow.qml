pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    required property bool isVertical
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return qsTr("Desktop");
        if (Config.bar.activeWindow.compact) {
            const parts = title.split(/\s+[\-–—]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly property int maxLength: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherLength = otherModules.reduce((acc, curr) => acc + (root.isVertical ? (curr.item.nonAnimHeight ?? curr.height) : (curr.item.nonAnimWidth ?? curr.width)), 0);
        return (root.isVertical ? bar.height : bar.width) - otherLength - (root.isVertical ? bar.rowSpacing : bar.columnSpacing) * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1

    function containsContent(x: real, y: real): bool {
        const iconPoint = icon.mapFromItem(root, x, y);
        if (icon.contains(iconPoint))
            return true;

        const titlePoint = current.mapFromItem(root, x, y);
        return current.contains(titlePoint);
    }

    clip: true
    implicitWidth: isVertical ? Math.max(icon.implicitWidth, current.implicitHeight) : icon.implicitWidth + current.implicitWidth + current.anchors.leftMargin
    implicitHeight: isVertical ? icon.implicitHeight + current.implicitWidth + current.anchors.topMargin : Math.max(icon.implicitHeight, current.implicitHeight)

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: root.containsContent(mouseX, mouseY) ? Qt.PointingHandCursor : Qt.ArrowCursor
            hoverEnabled: true
            onPositionChanged: {
                if (!root.containsContent(mouseX, mouseY))
                    return;

                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                if (!root.containsContent(mouseX, mouseY))
                    return;

                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.bar.mainCenter(root);
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter
        anchors.left: root.isVertical ? undefined : parent.left

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: root.windowTitle
        font.pointSize: root.Tokens.font.size.smaller
        font.family: root.Tokens.font.family.mono
        elide: Qt.ElideRight
        elideWidth: root.maxLength - (root.isVertical ? icon.height : icon.width)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: root.isVertical ? icon.horizontalCenter : undefined
        anchors.top: root.isVertical ? icon.bottom : undefined
        anchors.left: root.isVertical ? undefined : icon.right
        anchors.verticalCenter: root.isVertical ? undefined : icon.verticalCenter
        anchors.topMargin: root.isVertical ? Tokens.spacing.small : 0
        anchors.leftMargin: root.isVertical ? 0 : Tokens.spacing.small

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: root.current === this ? 1 : 0

        transform: [
            Translate {
                x: root.isVertical && root.Config.bar.activeWindow.inverted ? -text.implicitWidth + text.implicitHeight : 0
            },
            Rotation {
                angle: root.isVertical ? root.Config.bar.activeWindow.inverted ? 270 : 90 : 0
                origin.x: text.implicitHeight / 2
                origin.y: text.implicitHeight / 2
            }
        ]

        width: root.isVertical ? implicitHeight : implicitWidth
        height: root.isVertical ? implicitWidth : implicitHeight

        Behavior on opacity {
            Anim {}
        }
    }
}
