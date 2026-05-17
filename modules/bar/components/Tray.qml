pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool isVertical

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.normal : Tokens.padding.small
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.small : 0
    readonly property int layoutItemCount: Math.max(1, items.count)

    property bool expanded

    readonly property real nonAnimWidth: {
        if (isVertical)
            return Tokens.sizes.bar.innerWidth;
        if (!Config.bar.tray.compact)
            return layout.implicitWidth + padding * 2;
        return (expanded ? expandIcon.implicitWidth + layout.implicitWidth + spacing : expandIcon.implicitWidth) + padding * 2;
    }
    readonly property real nonAnimHeight: {
        if (!isVertical)
            return Tokens.sizes.bar.innerWidth;
        if (!Config.bar.tray.compact)
            return layout.implicitHeight + padding * 2;
        return (expanded ? expandIcon.implicitHeight + layout.implicitHeight + spacing : expandIcon.implicitHeight) + padding * 2;
    }

    clip: true
    visible: isVertical ? height > 0 : width > 0

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Grid {
        id: layout

        anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter
        anchors.top: root.isVertical ? parent.top : undefined
        anchors.left: root.isVertical ? undefined : parent.left
        anchors.topMargin: root.isVertical ? root.padding : 0
        anchors.leftMargin: root.isVertical ? 0 : root.padding
        rows: root.isVertical ? root.layoutItemCount : 1
        columns: root.isVertical ? 1 : root.layoutItemCount
        spacing: Tokens.spacing.small

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter
        anchors.bottom: root.isVertical ? parent.bottom : undefined
        anchors.right: root.isVertical ? undefined : parent.right

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: root.isVertical ? expandIconInner.implicitWidth : expandIconInner.implicitWidth - Tokens.padding.small * 2
            implicitHeight: root.isVertical ? expandIconInner.implicitHeight - Tokens.padding.small * 2 : expandIconInner.implicitHeight

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
                anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter
                anchors.bottom: root.isVertical ? parent.bottom : undefined
                anchors.right: root.isVertical ? undefined : parent.right
                anchors.bottomMargin: root.isVertical ? Config.bar.tray.background ? Tokens.padding.small : -Tokens.padding.small : 0
                anchors.rightMargin: root.isVertical ? 0 : Config.bar.tray.background ? Tokens.padding.small : -Tokens.padding.small
                text: root.isVertical ? "expand_less" : "chevron_left"
                font.pointSize: Tokens.font.size.large
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

                Behavior on anchors.bottomMargin {
                    Anim {}
                }

                Behavior on anchors.rightMargin {
                    Anim {}
                }
            }
        }
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
}
