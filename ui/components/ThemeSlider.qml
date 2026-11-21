import QtQuick
import QtQuick.Controls

Slider {
    id: control

    property var themePalette

    implicitWidth: 180
    implicitHeight: 32
    leftPadding: 9
    rightPadding: 9
    topPadding: 0
    bottomPadding: 0

    background: Rectangle {
        x: control.leftPadding
        y: (control.height - height) / 2
        width: control.availableWidth
        height: 6
        radius: 3
        color: control.themePalette.selection

        Rectangle {
            x: 0
            y: 0
            width: Math.max(0, control.visualPosition * parent.width)
            height: parent.height
            radius: parent.radius
            color: control.themePalette.accent
        }
    }

    handle: Rectangle {
        implicitWidth: 16
        implicitHeight: 16
        x: control.leftPadding +
           control.visualPosition * (control.availableWidth - width)
        y: (control.height - height) / 2
        radius: 8
        color: control.themePalette.foreground
        border.width: 2
        border.color: control.themePalette.accent
    }
}
