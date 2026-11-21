import QtQuick

Rectangle {
    id: preview

    required property var widget
    required property var palette

    radius: 10
    color: palette.dark_background
    border.width: 1
    border.color: palette.muted
    clip: true

    Image {
        id: previewImage
        anchors.fill: parent
        anchors.margins: 5
        source: preview.widget.preview ? "file://" + preview.widget.preview : ""
        visible: status === Image.Ready
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectFit
    }

    Column {
        anchors.centerIn: parent
        spacing: 4
        visible: previewImage.status !== Image.Ready

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "▦"
            color: preview.palette.accent
            font.pixelSize: 36
        }

        Text {
            text: "Preview unavailable"
            color: preview.palette.dark_foreground
            font.pixelSize: 9
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 7
        radius: 5
        color: preview.palette.background
        opacity: 0.9
        width: previewLabel.implicitWidth + 12
        height: previewLabel.implicitHeight + 6
        visible: preview.widget.preview_kind !== ""

        Text {
            id: previewLabel
            anchors.centerIn: parent
            text: preview.widget.preview_kind === "generated" ? "CAPTURED" : "PREVIEW"
            color: preview.palette.foreground
            font.pixelSize: 8
            font.weight: Font.Bold
        }
    }
}
