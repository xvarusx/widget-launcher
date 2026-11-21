import QtQuick
import QtQuick.Controls

CheckBox {
    id: control
    required property var palette

    implicitHeight: 34
    leftPadding: 0
    rightPadding: 0

    indicator: Rectangle {
        implicitWidth: 20
        implicitHeight: 20
        x: control.width - width
        y: (parent.height - height) / 2
        radius: 0
        color: control.checked ? control.palette.accent : Qt.lighter(control.palette.background, 1.35)
        border.width: 1
        border.color: control.checked ? control.palette.accent : control.palette.muted

        Text {
            anchors.centerIn: parent
            text: "✓"
            font.pixelSize: 13
            font.weight: Font.Bold
            color: control.palette.background
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        font.pixelSize: 13
        color: control.palette.foreground
        verticalAlignment: Text.AlignVCenter
        rightPadding: control.indicator.width + 12
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 0
        color: control.hovered ? Qt.alpha(control.palette.foreground, 0.05) : "transparent"
    }
}
