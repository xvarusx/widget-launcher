import QtQuick
import QtQuick.Controls

Switch {
    id: control

    property var themePalette

    implicitWidth: 42
    implicitHeight: 24
    spacing: 0

    indicator: Rectangle {
        x: control.leftPadding
        y: (control.height - height) / 2
        width: 38
        height: 20
        radius: height / 2
        color: control.checked ? control.themePalette.accent : control.themePalette.selection
        border.width: control.checked ? 0 : 1
        border.color: control.themePalette.muted

        Rectangle {
            width: 14
            height: 14
            radius: 7
            y: 3
            x: control.checked ? parent.width - width - 3 : 3
            color: control.checked
                ? control.themePalette.background
                : control.themePalette.dark_foreground

            Behavior on x {
                NumberAnimation { duration: 120 }
            }
        }
    }

    contentItem: Item { }
}
