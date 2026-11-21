import QtQuick
import QtQuick.Controls

Button {
    id: control

    property bool selected: false
    property var themePalette

    implicitHeight: 34
    leftPadding: 13
    rightPadding: 13

    contentItem: Text {
        text: control.text
        color: control.selected ? control.themePalette.background : control.themePalette.foreground
        font.pixelSize: 12
        font.weight: control.selected ? Font.DemiBold : Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 9
        color: control.selected ? control.themePalette.accent : control.themePalette.lighter_background
        border.width: control.selected ? 0 : 1
        border.color: control.themePalette.muted
        opacity: control.enabled ? 1 : 0.5
    }
}
