pragma ComponentBehavior: Bound

import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

GridLayout {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    required property string position
    readonly property bool isVertical: BarPosition.isVertical(position)
    readonly property int vPadding: Tokens.padding.large

    columns: isVertical ? 1 : repeater.count
    rows: isVertical ? repeater.count : 1
    rowSpacing: isVertical ? Tokens.spacing.normal : 0
    columnSpacing: isVertical ? 0 : Tokens.spacing.normal

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const loader = repeater.itemAt(i) as WrappedLoader;
            if (loader?.enabled && loader.id === "tray") {
                (loader.item as Tray).expanded = false;
            }
        }
    }

    function mainCenter(item: Item): real {
        const point = item.mapToItem(root, isVertical ? 0 : item.implicitWidth / 2, isVertical ? item.implicitHeight / 2 : 0);
        return isVertical ? point.y : point.x;
    }

    function checkPopout(x: real, y: real): bool {
        const ch = childAt(x, y) as WrappedLoader;

        if (ch?.id !== "tray")
            closeTray();

        if (!ch)
            return false;

        const id = ch.id;

        if (id === "statusIcons" && Config.bar.popouts.statusIcons) {
            const items = (ch.item as StatusIcons)?.items;
            if (!items)
                return false;

            const point = mapToItem(items, x, y);
            const icon = items.childAt(point.x, point.y);
            if (!icon)
                return false;

            popouts.currentName = icon.name;
            popouts.currentCenter = Qt.binding(() => mainCenter(icon));
            popouts.hasCurrent = true;
            return true;
        } else if (id === "tray" && Config.bar.popouts.tray) {
            const tray = ch.item as Tray;
            if (!tray)
                return false;

            const expandPoint = tray.expandIcon.mapFromItem(root, x, y);
            const onExpandIcon = tray.expandIcon.contains(expandPoint);
            if (Config.bar.tray.compact && !tray.expanded) {
                if (onExpandIcon) {
                    popouts.hasCurrent = false;
                    tray.expanded = true;
                    return true;
                }

                return false;
            }

            if (!Config.bar.tray.compact || (tray.expanded && !onExpandIcon)) {
                const layoutPoint = tray.layout.mapFromItem(root, x, y);
                const trayItem = tray.layout.childAt(layoutPoint.x, layoutPoint.y);
                const index = trayItem ? Array.from({ length: tray.items.count }, (_, i) => i).find(i => tray.items.itemAt(i) === trayItem) ?? -1 : -1;
                if (trayItem && index >= 0) {
                    popouts.currentName = `traymenu${index}`;
                    popouts.currentCenter = Qt.binding(() => mainCenter(trayItem));
                    popouts.hasCurrent = true;
                    return true;
                }

                return false;
            } else {
                popouts.hasCurrent = false;
                return true;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            const activeWindow = ch.item as ActiveWindow;
            if (!activeWindow)
                return false;

            const point = activeWindow.mapFromItem(root, x, y);
            if (!activeWindow.containsContent(point.x, point.y))
                return false;

            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = mainCenter(activeWindow);
            popouts.hasCurrent = true;
            return true;
        }

        return false;
    }

    function isInWorkspaces(item: Item, x: real, y: real): bool {
        if (!item)
            return false;

        const point = item.mapFromItem(root, x, y);
        return item.contains(point);
    }

    function statusIconAt(x: real, y: real): Item {
        const ch = childAt(x, y) as WrappedLoader;
        if (ch?.id !== "statusIcons")
            return null;

        const items = (ch.item as StatusIcons)?.items;
        if (!items)
            return null;

        const point = mapToItem(items, x, y);
        return items.childAt(point.x, point.y);
    }

    function adjustVolume(angleDelta: point): void {
        if (angleDelta.y > 0)
            Audio.incrementVolume();
        else if (angleDelta.y < 0)
            Audio.decrementVolume();
    }

    function adjustSourceVolume(angleDelta: point): void {
        if (angleDelta.y > 0)
            Audio.incrementSourceVolume();
        else if (angleDelta.y < 0)
            Audio.decrementSourceVolume();
    }

    function adjustBrightness(angleDelta: point): void {
        const monitor = Brightness.getMonitorForScreen(screen);
        if (angleDelta.y > 0)
            monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
        else if (angleDelta.y < 0)
            monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
    }

    function handleWheel(x: real, y: real, angleDelta: point): void {
        const ch = childAt(x, y) as WrappedLoader;
        if (ch?.id === "workspaces" && Config.bar.scrollActions.workspaces && isInWorkspaces(ch.item as Item, x, y)) {
            const delta = isVertical ? angleDelta.y : (angleDelta.x || angleDelta.y);
            if (delta === 0)
                return;

            const mon = (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(`togglespecialworkspace ${specialWs.slice(8)}`);
            else if (delta < 0 || (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? mon.activeWorkspace?.id : Hypr.activeWsId) > 1)
                Hypr.dispatch(`workspace r${delta > 0 ? "-" : "+"}1`);
            return;
        }

        const icon = statusIconAt(x, y);
        if (!icon)
            return;

        if (icon.name === "audio" && Config.bar.scrollActions.volume) {
            adjustVolume(angleDelta);
        } else if (icon.name === "microphone" && Config.bar.scrollActions.volume) {
            adjustSourceVolume(angleDelta);
        } else if (icon.name === "battery" && Config.bar.scrollActions.brightness) {
            adjustBrightness(angleDelta);
        }
    }

    Repeater {
        id: repeater

        model: Config.bar.entries

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: WrappedLoader {
                    Layout.fillHeight: enabled && root.isVertical
                    Layout.fillWidth: enabled && !root.isVertical
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: WrappedLoader {
                    sourceComponent: OsIcon {}
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: WrappedLoader {
                    sourceComponent: Workspaces {
                        screen: root.screen
                        fullscreen: root.fullscreen
                        isVertical: root.isVertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: WrappedLoader {
                    Layout.fillWidth: !root.isVertical
                    Layout.fillHeight: root.isVertical
                    visible: !root.fullscreen
                    sourceComponent: ActiveWindow {
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                        isVertical: root.isVertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: WrappedLoader {
                    visible: !root.fullscreen
                    sourceComponent: Tray {
                        isVertical: root.isVertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: WrappedLoader {
                    visible: !root.fullscreen
                    sourceComponent: Clock {
                        isVertical: root.isVertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: WrappedLoader {
                    visible: !root.fullscreen
                    sourceComponent: StatusIcons {
                        isVertical: root.isVertical
                    }
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: WrappedLoader {
                    sourceComponent: Power {
                        visibilities: root.visibilities
                    }
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required enabled
        required property string id
        required property int index

        function findFirstEnabled(): Item {
            const count = repeater.count;
            for (let i = 0; i < count; i++) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        function findLastEnabled(): Item {
            for (let i = repeater.count - 1; i >= 0; i--) {
                const item = repeater.itemAt(i);
                if (item?.enabled)
                    return item;
            }
            return null;
        }

        asynchronous: true
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: root.isVertical && findFirstEnabled() === this ? root.vPadding : 0
        Layout.bottomMargin: root.isVertical && findLastEnabled() === this ? root.vPadding : 0
        Layout.leftMargin: !root.isVertical && findFirstEnabled() === this ? root.vPadding : 0
        Layout.rightMargin: !root.isVertical && findLastEnabled() === this ? root.vPadding : 0

        visible: enabled
        active: enabled
    }
}
