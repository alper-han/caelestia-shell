pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

StackView {
    id: root

    required property PopoutState popouts
    required property QsMenuHandle trayItem

    implicitWidth: currentItem?.implicitWidth ?? 0
    implicitHeight: currentItem?.implicitHeight ?? 0

    initialItem: SubMenu {
        handle: root.trayItem
    }

    pushEnter: NoAnim {}
    pushExit: NoAnim {}
    popEnter: NoAnim {}
    popExit: NoAnim {}

    Component {
        id: subMenuComp

        SubMenu {}
    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    component SubMenu: Column {
        id: menu

        required property QsMenuHandle handle
        property bool isSubMenu
        property bool shown
        readonly property real maxItemWidth: Tokens.sizes.bar.trayMenuWidth
        readonly property real itemWidth: Math.min(maxItemWidth, implicitContentWidth)
        readonly property real implicitContentWidth: {
            let width = 0;
            for (let i = 0; i < menuItems.count; i++)
                width = Math.max(width, menuItems.itemAt(i)?.naturalWidth ?? 0);
            return width;
        }

        padding: Tokens.padding.smaller
        spacing: Tokens.spacing.small

        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.8

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        QsMenuOpener {
            id: menuOpener

            menu: menu.handle
        }

        Repeater {
            id: menuItems

            model: menuOpener.children

            StyledRect {
                id: item

                required property QsMenuEntry modelData
                readonly property real naturalWidth: modelData.isSeparator ? 0 : naturalLabel.implicitWidth + (modelData.icon !== "" ? naturalLabel.implicitHeight + Tokens.spacing.smaller : 0) + (modelData.hasChildren ? naturalLabel.implicitHeight + Tokens.spacing.normal : 0)

                implicitWidth: menu.itemWidth
                implicitHeight: modelData.isSeparator ? 1 : children.implicitHeight

                radius: Tokens.rounding.full
                color: modelData.isSeparator ? Colours.palette.m3outlineVariant : "transparent"

                StyledText {
                    id: naturalLabel

                    text: item.modelData.text
                    visible: false
                }

                Loader {
                    id: children

                    asynchronous: true
                    anchors.left: parent.left
                    anchors.right: parent.right

                    active: !item.modelData.isSeparator

                    sourceComponent: Item {
                        implicitWidth: icon.implicitWidth + (icon.active ? label.anchors.leftMargin : 0) + labelMetrics.advanceWidth + (expand.active ? expand.implicitWidth + expand.anchors.leftMargin : 0)
                        implicitHeight: label.implicitHeight

                        StateLayer {
                            anchors.margins: -Tokens.padding.small / 2
                            anchors.leftMargin: -Tokens.padding.smaller
                            anchors.rightMargin: -Tokens.padding.smaller

                            radius: item.radius
                            disabled: !item.modelData.enabled

                            onClicked: {
                                const entry = item.modelData;
                                if (entry.hasChildren)
                                    root.push(subMenuComp.createObject(null, {
                                        handle: entry,
                                        isSubMenu: true
                                    }));
                                else {
                                    item.modelData.triggered();
                                    root.popouts.hasCurrent = false;
                                }
                            }
                        }

                        Loader {
                            id: icon

                            asynchronous: true
                            anchors.left: parent.left

                            active: item.modelData.icon !== ""

                            sourceComponent: IconImage {
                                asynchronous: true
                                implicitSize: label.implicitHeight

                                source: item.modelData.icon
                            }
                        }

                        StyledText {
                            id: label

                            anchors.left: icon.right
                            anchors.leftMargin: icon.active ? Tokens.spacing.smaller : 0

                            text: labelMetrics.elidedText
                            color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                        }

                        TextMetrics {
                            id: labelMetrics

                            text: item.modelData.text
                            font.pointSize: label.font.pointSize
                            font.family: label.font.family

                            elide: Text.ElideRight
                            elideWidth: menu.itemWidth - (icon.active ? icon.implicitWidth + label.anchors.leftMargin : 0) - (expand.active ? expand.implicitWidth + expand.anchors.leftMargin : 0)
                        }

                        Loader {
                            id: expand

                            asynchronous: true
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.leftMargin: Tokens.spacing.normal

                            active: item.modelData.hasChildren

                            sourceComponent: MaterialIcon {
                                text: "chevron_right"
                                color: item.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                            }
                        }
                    }
                }
            }
        }

        Loader {
            asynchronous: true
            active: menu.isSubMenu

            sourceComponent: Item {
                implicitWidth: back.implicitWidth
                implicitHeight: back.implicitHeight + Tokens.spacing.small / 2

                Item {
                    anchors.bottom: parent.bottom
                    implicitWidth: back.implicitWidth
                    implicitHeight: back.implicitHeight

                    StyledRect {
                        anchors.fill: parent
                        anchors.margins: -Tokens.padding.small / 2
                        anchors.leftMargin: -Tokens.padding.smaller
                        anchors.rightMargin: -Tokens.padding.smaller * 2

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3secondaryContainer

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onSecondaryContainer
                            onClicked: root.pop()
                        }
                    }

                    Row {
                        id: back

                        anchors.verticalCenter: parent.verticalCenter

                        MaterialIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "chevron_left"
                            color: Colours.palette.m3onSecondaryContainer
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Back")
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }
                }
            }
        }
    }
}
