pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen
    required property bool isVertical
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property string activeSpecial: (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? monitor : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace?.name ?? ""

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: mask
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: root.isVertical ? Gradient.Vertical : Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.3
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: root.isVertical ? parent.right : undefined
            anchors.bottom: root.isVertical ? undefined : parent.bottom

            radius: Tokens.rounding.full
            implicitWidth: root.isVertical ? 0 : parent.width / 2
            implicitHeight: root.isVertical ? parent.height / 2 : 0
            opacity: (root.isVertical ? view.contentY : view.contentX) > 0 ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.left: root.isVertical ? parent.left : undefined
            anchors.top: root.isVertical ? undefined : parent.top

            radius: Tokens.rounding.full
            implicitWidth: root.isVertical ? 0 : parent.width / 2
            implicitHeight: root.isVertical ? parent.height / 2 : 0
            opacity: root.isVertical ? view.contentY < view.contentHeight - parent.height + Tokens.padding.small ? 0 : 1 : view.contentX < view.contentWidth - parent.width + Tokens.padding.small ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }
    }

    ListView {
        id: view

        anchors.fill: parent
        orientation: root.isVertical ? ListView.Vertical : ListView.Horizontal
        spacing: Tokens.spacing.normal
        interactive: false

        currentIndex: model.values.findIndex(w => w.name === root.activeSpecial)
        onCurrentIndexChanged: currentIndex = Qt.binding(() => model.values.findIndex(w => w.name === root.activeSpecial))

        model: ScriptModel {
            values: Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (!GlobalConfig.bar.workspaces.perMonitorWorkspaces || w.monitor === root.monitor))
        }

        preferredHighlightBegin: 0
        preferredHighlightEnd: root.isVertical ? height : width
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: false
        highlight: Item {
            x: root.isVertical ? 0 : view.currentItem?.x ?? 0
            y: root.isVertical ? view.currentItem?.y ?? 0 : 0
            implicitWidth: root.isVertical ? 0 : (view.currentItem as SpecialWsDelegate)?.size ?? 0
            implicitHeight: root.isVertical ? (view.currentItem as SpecialWsDelegate)?.size ?? 0 : 0

            Behavior on x {
                Anim {}
            }

            Behavior on y {
                Anim {}
            }
        }

        delegate: SpecialWsDelegate {}

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        remove: Transition {
            Anim {
                property: "scale"
                to: 0.5
                type: Anim.StandardSmall
            }
            Anim {
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
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

        displaced: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    Loader {
        asynchronous: true
        active: Config.bar.workspaces.activeIndicator
        anchors.fill: parent

        sourceComponent: Item {
            StyledClippingRect {
                id: indicator

                anchors.left: root.isVertical ? parent.left : undefined
                anchors.right: root.isVertical ? parent.right : undefined
                anchors.top: root.isVertical ? undefined : parent.top
                anchors.bottom: root.isVertical ? undefined : parent.bottom

                x: root.isVertical ? 0 : (view.currentItem?.x ?? 0) - view.contentX
                y: root.isVertical ? (view.currentItem?.y ?? 0) - view.contentY : 0
                implicitWidth: root.isVertical ? 0 : (view.currentItem as SpecialWsDelegate)?.size ?? 0
                implicitHeight: root.isVertical ? (view.currentItem as SpecialWsDelegate)?.size ?? 0 : 0

                color: Colours.palette.m3tertiary
                radius: Tokens.rounding.full

                Colouriser {
                    source: view
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onTertiary

                    anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
                    anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter

                    x: root.isVertical ? 0 : -indicator.x
                    y: root.isVertical ? -indicator.y : 0
                    implicitWidth: view.width
                    implicitHeight: view.height
                }

                Behavior on x {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on y {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitWidth {
                    Anim {
                        type: Anim.Emphasized
                    }
                }

                Behavior on implicitHeight {
                    Anim {
                        type: Anim.Emphasized
                    }
                }
            }
        }
    }

    MouseArea {
        property real startCoord

        anchors.fill: view

        drag.target: view.contentItem
        drag.axis: root.isVertical ? Drag.YAxis : Drag.XAxis
        drag.maximumY: root.isVertical ? 0 : view.contentItem.y
        drag.minimumY: root.isVertical ? Math.min(0, view.height - view.contentHeight - Tokens.padding.small) : view.contentItem.y
        drag.maximumX: root.isVertical ? view.contentItem.x : 0
        drag.minimumX: root.isVertical ? view.contentItem.x : Math.min(0, view.width - view.contentWidth - Tokens.padding.small)

        onPressed: event => startCoord = root.isVertical ? event.y : event.x

        onClicked: event => {
            if (Math.abs((root.isVertical ? event.y : event.x) - startCoord) > drag.threshold)
                return;

            const ws = view.itemAt(event.x, event.y) as SpecialWsDelegate;
            if (ws?.modelData)
                Hypr.dispatch(`togglespecialworkspace ${ws.modelData.name.slice(8)}`);
            else
                Hypr.dispatch("togglespecialworkspace special");
        }
    }

    component SpecialWsDelegate: GridLayout {
        id: ws

        required property HyprlandWorkspace modelData
        readonly property int size: root.isVertical ? label.Layout.preferredHeight + (hasWindows ? windows.implicitHeight + Tokens.padding.small : 0) : label.Layout.preferredWidth + (hasWindows ? windows.implicitWidth + Tokens.padding.small : 0)
        property int wsId
        property string icon
        property bool hasWindows

        width: root.isVertical ? view.width : size
        height: root.isVertical ? size : view.height

        columns: root.isVertical ? 1 : 2
        rows: root.isVertical ? 2 : 1
        rowSpacing: 0
        columnSpacing: 0

        Component.onCompleted: {
            wsId = modelData.id;
            icon = Icons.getSpecialWsIcon(modelData.name);
            hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && modelData.lastIpcObject.windows > 0;
        }

        Connections {
            function onIdChanged(): void {
                if (ws.modelData)
                    ws.wsId = ws.modelData.id;
            }

            function onNameChanged(): void {
                if (ws.modelData)
                    ws.icon = Icons.getSpecialWsIcon(ws.modelData.name);
            }

            function onLastIpcObjectChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: ws.modelData
        }

        Connections {
            function onShowWindowsOnSpecialWorkspacesChanged(): void {
                if (ws.modelData)
                    ws.hasWindows = root.Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
            }

            target: root.Config.bar.workspaces
        }

        Loader {
            id: label

            asynchronous: true

            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2
            Layout.preferredWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

            sourceComponent: ws.icon.length === 1 ? letterComp : iconComp

            Component {
                id: iconComp

                MaterialIcon {
                    fill: 1
                    text: ws.icon
                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignHCenter
                }
            }

            Component {
                id: letterComp

                StyledText {
                    text: ws.icon
                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignHCenter
                }
            }
        }

        Loader {
            id: windows

            asynchronous: true

            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: root.isVertical
            Layout.fillWidth: !root.isVertical
            Layout.preferredHeight: root.isVertical ? implicitHeight : -1
            Layout.preferredWidth: root.isVertical ? -1 : implicitWidth

            visible: active
            active: ws.hasWindows

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
                            const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws.wsId);
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

            Behavior on Layout.preferredHeight {
                Anim {}
            }

            Behavior on Layout.preferredWidth {
                Anim {}
            }
        }
    }
}
