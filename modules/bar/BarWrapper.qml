pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    readonly property string position: BarPosition.resolvedPosition(Config.bar.position)
    readonly property bool isVertical: BarPosition.isVertical(position)
    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)

    readonly property int padding: Math.max(Tokens.padding.smaller, Config.border.thickness)
    readonly property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int contentHeight: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int clampedWidth: Math.max(Config.border.minThickness, implicitWidth)
    readonly property int clampedHeight: Math.max(Config.border.minThickness, implicitHeight)
    readonly property int clampedThickness: isVertical ? clampedWidth : clampedHeight
    readonly property int contentThickness: isVertical ? contentWidth : contentHeight
    readonly property int exclusiveZone: fullscreen ? 0 : (!disabled && (Config.bar.persistent || visibilities.bar) ? contentThickness : Config.border.thickness)
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || visibilities.bar || isHovered)
    property bool reloadContent: true
    property bool isHovered

    onPositionChanged: {
        isHovered = false;
        closeTray();
        popouts.close();
    }

    onIsVerticalChanged: {
        popouts.close();
        reloadContent = false;
        Qt.callLater(() => {
            reloadContent = true;
        });
    }

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(x: real, y: real): bool {
        const barItem = content.item as Bar;
        if (!barItem || !parent)
            return false;

        const point = barItem.mapFromItem(parent, x, y);
        return barItem.checkPopout(point.x, point.y);
    }

    function handleWheel(x: real, y: real, angleDelta: point): void {
        const barItem = content.item as Bar;
        if (!barItem || !parent)
            return;

        const point = barItem.mapFromItem(parent, x, y);
        barItem.handleWheel(point.x, point.y, angleDelta);
    }

    clip: true
    visible: isVertical ? width > 0 : height > 0
    implicitWidth: isVertical && !fullscreen ? Config.border.thickness : 0
    implicitHeight: !isVertical && !fullscreen ? Config.border.thickness : 0

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.isVertical ? root.contentWidth : 0
            root.implicitHeight: root.isVertical ? 0 : root.contentHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: root.isVertical ? "implicitWidth" : "implicitHeight"
                type: Anim.DefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: root.isVertical ? "implicitWidth" : "implicitHeight"
                type: Anim.Emphasized
            }
        }
    ]

    x: BarPosition.isRight(position) && parent ? parent.width - width : 0
    y: BarPosition.isBottom(position) && parent ? parent.height - height : 0
    width: isVertical ? implicitWidth : parent ? parent.width : 0
    height: isVertical ? parent ? parent.height : 0 : implicitHeight

    Loader {
        id: content

        x: root.isVertical && BarPosition.isLeft(root.position) ? root.width - width : 0
        y: !root.isVertical && BarPosition.isTop(root.position) ? root.height - height : 0
        width: root.isVertical ? root.contentWidth : root.width
        height: root.isVertical ? root.height : root.contentHeight

        active: root.reloadContent && (root.shouldBeVisible || root.visible)

        sourceComponent: Bar {
            width: content.width
            height: content.height
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
            position: root.position
        }
    }
}
