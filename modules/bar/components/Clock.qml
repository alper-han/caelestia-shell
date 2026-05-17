pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property bool isVertical

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.normal : Tokens.padding.small

    implicitWidth: isVertical ? Tokens.sizes.bar.innerWidth : horizontalLayout.implicitWidth + root.padding * 2
    implicitHeight: isVertical ? verticalLayout.implicitHeight + root.padding * 2 : Tokens.sizes.bar.innerWidth

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Column {
        id: verticalLayout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small
        visible: root.isVertical

        Loader {
            asynchronous: true
            anchors.horizontalCenter: parent.horizontalCenter

            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            visible: Config.bar.clock.showDate

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format("ddd\nd")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.sans
            color: root.colour
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.bar.clock.showDate
            width: parent.width * 0.8
            height: 1
            color: root.colour
            opacity: 0.2
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format(GlobalConfig.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.mono
            color: root.colour
        }
    }

    Row {
        id: horizontalLayout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small
        visible: !root.isVertical

        Loader {
            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter

            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter

            visible: Config.bar.clock.showDate

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format("ddd d")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.sans
            color: root.colour
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: Config.bar.clock.showDate
            width: 1
            height: parent.height * 0.8
            color: root.colour
            opacity: 0.2
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter

            horizontalAlignment: StyledText.AlignHCenter
            text: Time.format(GlobalConfig.services.useTwelveHourClock ? "hh:mm A" : "hh:mm")
            font.pointSize: Tokens.font.size.smaller
            font.family: Tokens.font.family.mono
            color: root.colour
        }
    }
}
