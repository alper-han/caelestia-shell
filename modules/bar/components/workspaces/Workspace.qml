pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

GridLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset
    required property bool isVertical

    readonly property bool isWorkspace: true
    readonly property int size: isVertical ? implicitHeight + (hasWindows ? Tokens.padding.small : 0) : implicitWidth + (hasWindows ? Tokens.padding.small : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    Layout.alignment: Qt.AlignCenter
    Layout.preferredHeight: isVertical ? size : Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2
    Layout.preferredWidth: isVertical ? Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2 : size

    columns: isVertical ? 1 : 2
    rows: isVertical ? 2 : 1
    rowSpacing: 0
    columnSpacing: 0

    StyledText {
        id: indicator

        Layout.alignment: Qt.AlignCenter
        Layout.preferredHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2
        Layout.preferredWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

        animate: true
        text: {
            const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
            const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
            let displayName = wsName.toString();
            if (Config.bar.workspaces.capitalisation.toLowerCase() === "upper") {
                displayName = displayName.toUpperCase();
            } else if (Config.bar.workspaces.capitalisation.toLowerCase() === "lower") {
                displayName = displayName.toLowerCase();
            }
            const label = Config.bar.workspaces.label || displayName;
            const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
            const activeLabel = Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
            return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
        }
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
        verticalAlignment: Qt.AlignVCenter
        horizontalAlignment: Qt.AlignHCenter
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: root.isVertical
        Layout.fillWidth: !root.isVertical
        Layout.topMargin: root.isVertical ? -Tokens.sizes.bar.innerWidth / 10 : 0
        Layout.leftMargin: root.isVertical ? 0 : -Tokens.sizes.bar.innerWidth / 10

        visible: active
        active: root.hasWindows

        sourceComponent: Grid {
            columns: root.isVertical ? 1 : children.length
            rows: root.isVertical ? children.length : 1
            spacing: 0

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
                model: ScriptModel {
                    values: {
                        const ws = root.ws;
                        const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws);
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    Behavior on Layout.preferredWidth {
        Anim {}
    }
}
