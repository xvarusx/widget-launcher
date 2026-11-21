import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    property var themePalette

    implicitHeight: 36
    leftPadding: 11
    rightPadding: 30

    contentItem: Text {
        leftPadding: 2
        text: control.displayText
        color: control.themePalette.foreground
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: control.width - width - 10
        y: (control.height - height) / 2
        text: "▾"
        color: control.themePalette.dark_foreground
        font.pixelSize: 13
    }

    background: Rectangle {
        radius: Number(control.themePalette.corner_radius || 0)
        color: control.themePalette.lighter_background
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus
            ? control.themePalette.accent : control.themePalette.muted
    }

    delegate: ItemDelegate {
        required property var model
        required property int index
        width: control.width
        height: 34
        highlighted: control.highlightedIndex === index

        contentItem: Text {
            text: control.textAt(index)
            color: highlighted ? control.themePalette.background : control.themePalette.foreground
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }

        background: Rectangle {
            color: highlighted ? control.themePalette.accent : control.themePalette.background
            radius: Number(control.themePalette.corner_radius || 0)
        }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        padding: 4

        background: Rectangle {
            color: control.themePalette.background
            radius: Number(control.themePalette.corner_radius || 0)
            border.width: 1
            border.color: control.themePalette.muted
        }

        contentItem: ListView {
            clip: true
            implicitHeight: Math.min(contentHeight, 220)
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
