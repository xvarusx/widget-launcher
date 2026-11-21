import QtQuick
import QtQuick.Controls

CheckBox {
    id: control

    property var themePalette

    spacing: 10
    implicitHeight: 34

    contentItem: Text {
        text: control.text
        color: control.enabled ? control.themePalette.foreground : control.themePalette.dark_foreground
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
        wrapMode: Text.WordWrap
    }

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: control.leftPadding
        y: (control.height - height) / 2
        radius: Number(control.themePalette.corner_radius || 0)
        color: control.checked ? control.themePalette.accent : control.themePalette.dark_background
        border.width: control.checked ? 0 : 1
        border.color: control.themePalette.muted

        Text {
            anchors.centerIn: parent
            text: "✓"
            visible: control.checked
            color: control.themePalette.background
            font.pixelSize: 13
            font.weight: Font.Bold
        }
    }
}
