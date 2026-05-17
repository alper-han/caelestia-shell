pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen
    required property bool isVertical

    readonly property bool onSpecial: (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: GlobalConfig.bar.workspaces.perMonitorWorkspaces ? (Hypr.monitorFor(screen).activeWorkspace?.id ?? 1) : Hypr.activeWsId

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }
    readonly property int groupOffset: Math.floor((activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown

    property real blur: onSpecial ? 1 : 0

    implicitWidth: isVertical ? Tokens.sizes.bar.innerWidth : layout.implicitWidth + Tokens.padding.small * 2
    implicitHeight: isVertical ? layout.implicitHeight + Tokens.padding.small * 2 : Tokens.sizes.bar.innerWidth

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        Loader {
            asynchronous: true
            active: Config.bar.workspaces.occupiedBg

            anchors.fill: parent
            anchors.margins: Tokens.padding.small

            sourceComponent: OccupiedBg {
                workspaces: workspaces
                occupied: root.occupied
                groupOffset: root.groupOffset
                isVertical: root.isVertical
            }
        }

        GridLayout {
            id: layout

            anchors.centerIn: parent
            columns: root.isVertical ? 1 : Config.bar.workspaces.shown
            rows: root.isVertical ? Config.bar.workspaces.shown : 1
            rowSpacing: root.isVertical ? Math.floor(Tokens.spacing.small / 2) : 0
            columnSpacing: root.isVertical ? 0 : Math.floor(Tokens.spacing.small / 2)

            Repeater {
                id: workspaces

                model: Config.bar.workspaces.shown

                Workspace {
                    activeWsId: root.activeWsId
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                    isVertical: root.isVertical
                }
            }
        }

        Loader {
            asynchronous: true
            anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
            anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter
            active: Config.bar.workspaces.activeIndicator

            sourceComponent: ActiveIndicator {
                activeWsId: root.activeWsId
                workspaces: workspaces
                mask: layout
                fullscreen: root.fullscreen
                isVertical: root.isVertical
            }
        }

        MouseArea {
            anchors.fill: layout
            onClicked: event => {
                const ws = (layout.childAt(event.x, event.y) as Workspace)?.ws;
                if (Hypr.activeWsId !== ws)
                    Hypr.dispatch(`workspace ${ws}`);
                else
                    Hypr.dispatch("togglespecialworkspace special");
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Loader {
        id: specialWs

        asynchronous: true

        anchors.fill: parent
        anchors.margins: Tokens.padding.small

        active: opacity > 0

        scale: root.onSpecial ? 1 : 0.5
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: SpecialWorkspaces {
            screen: root.screen
            isVertical: root.isVertical
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
