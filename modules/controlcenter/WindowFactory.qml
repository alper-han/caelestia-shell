pragma Singleton

import QtQuick
import Quickshell
import qs.components
import qs.services

Singleton {
    id: root

    property FloatingWindow currentWindow

    function centerWindow(win: FloatingWindow): void {
        if (!win || !win.screen)
            return;

        const x = Math.round(win.screen.x + (win.screen.width - win.implicitWidth) / 2);
        const y = Math.round(win.screen.y + (win.screen.height - win.implicitHeight) / 2);
        Hypr.dispatch(`movewindowpixel exact ${x} ${y},title:^Caelestia Settings`);
    }

    function focusedScreen(): ShellScreen {
        const focusedMonitor = Hypr.focusedMonitor;
        return Screens.screens.find(s => Hypr.monitorFor(s) === focusedMonitor) ?? Quickshell.screens.find(s => Hypr.monitorFor(s) === focusedMonitor) ?? Quickshell.screens[0];
    }

    function create(parent: Item, props: var): void {
        const windowProps = props ? Object.assign({}, props) : {};
        if (!windowProps.screen) {
            const screen = focusedScreen();
            if (screen)
                windowProps.screen = screen;
        }

        if (currentWindow)
            currentWindow.destroy();

        currentWindow = controlCenter.createObject(parent ?? dummy, windowProps) as FloatingWindow;
    }

    QtObject {
        id: dummy
    }

    Component {
        id: controlCenter

        FloatingWindow {
            id: win

            property alias active: cc.active
            property alias navExpanded: cc.navExpanded

            color: Colours.tPalette.m3surface

            onVisibleChanged: {
                if (!visible) {
                    destroy();
                } else {
                    centerTimer.restart();
                }
            }

            Timer {
                id: centerTimer

                property int attempts

                interval: 50
                repeat: true
                onTriggered: {
                    root.centerWindow(win);

                    if (++attempts >= 5) {
                        stop();
                        attempts = 0;
                    }
                }
            }

            Component.onDestruction: {
                if (root.currentWindow === win)
                    root.currentWindow = null;
            }

            implicitWidth: cc.implicitWidth
            implicitHeight: cc.implicitHeight

            minimumSize.width: implicitWidth
            minimumSize.height: implicitHeight
            maximumSize.width: implicitWidth
            maximumSize.height: implicitHeight

            title: qsTr("Caelestia Settings - %1").arg(cc.active.slice(0, 1).toUpperCase() + cc.active.slice(1))

            ControlCenter {
                id: cc

                anchors.fill: parent
                screen: win.screen
                onClose: win.destroy()
                floating: true
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
