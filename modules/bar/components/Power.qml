import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities

    implicitWidth: icon.implicitHeight + Tokens.padding.small * 2
    implicitHeight: icon.implicitHeight + Tokens.padding.small * 2

    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.full
        onClicked: root.visibilities.session = !root.visibilities.session
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -1

        text: "power_settings_new"
        color: Colours.palette.m3error
        font.bold: true
        font.pointSize: Tokens.font.size.normal
    }
}
