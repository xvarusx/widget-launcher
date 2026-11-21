import QtQuick
import QtQuick.Controls

Slider {
    id: control

    property var themePalette

    implicitHeight: 28

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: 5
        radius: Number(control.themePalette.corner_radius || 0)
        color: control.themePalette.selection

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: control.themePalette.accent
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 14
        height: 14
        radius: Number(control.themePalette.corner_radius || 0)
        color: control.themePalette.foreground
        border.width: 2
        border.color: control.themePalette.accent
    }
}
