import QtQuick
import QtQuick.Controls

Button {
    id: control

    property var themeColors
    property bool accent: false

    implicitHeight: 34
    leftPadding: 12
    rightPadding: 12

    contentItem: Text {
        text: control.text
        color: control.accent ? control.themeColors.background : control.themeColors.foreground
        font.pixelSize: 11
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 8
        color: control.accent
            ? control.themeColors.accent
            : control.down
                ? control.themeColors.selection
                : control.hovered
                    ? control.themeColors.selection
                    : control.themeColors.lighter_background
        border.width: control.accent ? 0 : 1
        border.color: control.themeColors.muted
        opacity: control.enabled ? 1 : 0.45
    }
}
