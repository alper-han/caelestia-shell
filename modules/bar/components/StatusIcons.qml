pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    required property bool isVertical

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    readonly property bool hasLockStatus: Config.bar.status.showLockStatus && (Hypr.capsLock || Hypr.numLock)
    readonly property int visibleItemCount: [
        Config.bar.status.showLockStatus,
        Config.bar.status.showAudio,
        Config.bar.status.showMicrophone,
        Config.bar.status.showKbLayout,
        Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi),
        Config.bar.status.showNetwork && Nmcli.activeEthernet,
        Config.bar.status.showBluetooth,
        Config.bar.status.showBattery
    ].filter(v => v).length
    readonly property int layoutItemCount: Math.max(1, visibleItemCount)

    clip: true
    implicitWidth: isVertical ? Tokens.sizes.bar.innerWidth : iconColumn.implicitWidth + Tokens.padding.normal * 2 - (!hasLockStatus ? iconColumn.columnSpacing : 0)
    implicitHeight: isVertical ? iconColumn.implicitHeight + Tokens.padding.normal * 2 - (!hasLockStatus ? iconColumn.rowSpacing : 0) : Tokens.sizes.bar.innerWidth

    GridLayout {
        id: iconColumn

        anchors.centerIn: parent

        rows: root.isVertical ? root.layoutItemCount : 1
        columns: root.isVertical ? 1 : root.layoutItemCount
        rowSpacing: root.isVertical ? Tokens.spacing.smaller / 2 : 0
        columnSpacing: root.isVertical ? 0 : Tokens.spacing.smaller / 2

        WrappedLoader {
            name: "lockstatus"
            active: Config.bar.status.showLockStatus

            sourceComponent: GridLayout {
                rows: root.isVertical ? 2 : 1
                columns: root.isVertical ? 1 : 2
                rowSpacing: 0
                columnSpacing: 0

                Item {
                    implicitWidth: root.isVertical ? capslockIcon.implicitWidth : Hypr.capsLock ? capslockIcon.implicitWidth : 0
                    implicitHeight: root.isVertical ? Hypr.capsLock ? capslockIcon.implicitHeight : 0 : Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

                    MaterialIcon {
                        id: capslockIcon

                        anchors.centerIn: parent

                        scale: Hypr.capsLock ? 1 : 0.5
                        opacity: Hypr.capsLock ? 1 : 0

                        text: "keyboard_capslock_badge"
                        color: root.colour

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {}
                    }

                    Behavior on implicitHeight {
                        Anim {}
                    }
                }

                Item {
                    Layout.topMargin: root.isVertical && Hypr.capsLock && Hypr.numLock ? iconColumn.rowSpacing : 0
                    Layout.leftMargin: !root.isVertical && Hypr.capsLock && Hypr.numLock ? iconColumn.columnSpacing : 0

                    implicitWidth: root.isVertical ? numlockIcon.implicitWidth : Hypr.numLock ? numlockIcon.implicitWidth : 0
                    implicitHeight: root.isVertical ? Hypr.numLock ? numlockIcon.implicitHeight : 0 : Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2

                    MaterialIcon {
                        id: numlockIcon

                        anchors.centerIn: parent

                        scale: Hypr.numLock ? 1 : 0.5
                        opacity: Hypr.numLock ? 1 : 0

                        text: "looks_one"
                        color: root.colour

                        Behavior on opacity {
                            Anim {}
                        }

                        Behavior on scale {
                            Anim {}
                        }
                    }

                    Behavior on implicitWidth {
                        Anim {}
                    }

                    Behavior on implicitHeight {
                        Anim {}
                    }
                }
            }
        }

        WrappedLoader {
            name: "audio"
            active: Config.bar.status.showAudio

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                color: root.colour
            }
        }

        WrappedLoader {
            name: "microphone"
            active: Config.bar.status.showMicrophone

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                color: root.colour
            }
        }

        WrappedLoader {
            name: "kblayout"
            active: Config.bar.status.showKbLayout

            sourceComponent: StyledText {
                animate: true
                text: Hypr.kbLayout
                color: root.colour
                font.family: Tokens.font.family.mono
            }
        }

        WrappedLoader {
            name: "network"
            active: Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi)

            sourceComponent: MaterialIcon {
                animate: true
                text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                color: root.colour
            }
        }

        WrappedLoader {
            name: "ethernet"
            active: Config.bar.status.showNetwork && Nmcli.activeEthernet

            sourceComponent: MaterialIcon {
                animate: true
                text: "cable"
                color: root.colour
            }
        }

        WrappedLoader {
            Layout.preferredHeight: root.isVertical ? implicitHeight : -1
            Layout.preferredWidth: root.isVertical ? -1 : implicitWidth

            name: "bluetooth"
            active: Config.bar.status.showBluetooth

            sourceComponent: GridLayout {
                rows: root.isVertical ? 1 + Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected).length : 1
                columns: root.isVertical ? 1 : 1 + Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected).length
                rowSpacing: root.isVertical ? Tokens.spacing.smaller / 2 : 0
                columnSpacing: root.isVertical ? 0 : Tokens.spacing.smaller / 2

                MaterialIcon {
                    animate: true
                    text: {
                        if (!Bluetooth.defaultAdapter?.enabled) // qmllint disable unresolved-type
                            return "bluetooth_disabled";
                        if (Bluetooth.devices.values.some(d => d.connected)) // qmllint disable unresolved-type
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.colour
                }

                Repeater {
                    model: ScriptModel {
                        values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected) // qmllint disable unresolved-type
                    }

                    MaterialIcon {
                        id: device

                        required property BluetoothDevice modelData

                        animate: true
                        text: Icons.getBluetoothIcon(modelData?.icon)
                        color: root.colour
                        fill: 1

                        SequentialAnimation on opacity {
                            running: device.modelData?.state !== BluetoothDeviceState.Connected // qmllint disable unresolved-type
                            alwaysRunToEnd: true
                            loops: Animation.Infinite

                            Anim {
                                from: 1
                                to: 0
                                duration: Tokens.anim.durations.large
                                easing: Tokens.anim.standardAccel
                            }
                            Anim {
                                from: 0
                                to: 1
                                duration: Tokens.anim.durations.large
                                easing: Tokens.anim.standardDecel
                            }
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

        WrappedLoader {
            name: "battery"
            active: Config.bar.status.showBattery

            sourceComponent: MaterialIcon {
                animate: true
                text: {
                    if (!UPower.displayDevice.isLaptopBattery) {
                        if (PowerProfiles.profile === PowerProfile.PowerSaver)
                            return "energy_savings_leaf";
                        if (PowerProfiles.profile === PowerProfile.Performance)
                            return "rocket_launch";
                        return "balance";
                    }

                    const perc = UPower.displayDevice.percentage;
                    const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state);
                    if (perc === 1)
                        return charging ? "battery_charging_full" : "battery_full";
                    let level = Math.floor(perc * 7);
                    if (charging && (level === 4 || level === 1))
                        level--;
                    return charging ? `battery_charging_${(level + 3) * 10}` : `battery_${level}_bar`;
                }
                color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error
                fill: 1
            }
        }
    }

    component WrappedLoader: Loader {
        required property string name

        asynchronous: true
        Layout.alignment: Qt.AlignCenter
        visible: active
    }
}
