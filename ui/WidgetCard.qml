import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card

    required property var widget
    required property var service
    property string viewMode: "grid"

    readonly property bool isFavorite:
        (service.settings.favorites || []).indexOf(widget.name) >= 0
    readonly property var palette: service.theme

    width: viewMode === "grid" ? 218 : 1
    height: viewMode === "grid" ? 246 : 104
    radius: 14
    color: palette.lighter_background
    border.width: 1
    border.color: palette.muted

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        visible: card.viewMode === "list"

        WidgetPreview {
            Layout.preferredWidth: 112
            Layout.fillHeight: true
            widget: card.widget
            palette: card.palette
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: card.widget.label || card.widget.name
                color: card.palette.foreground
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: card.widget.description || card.widget.category
                color: card.palette.dark_foreground
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 6

                Rectangle {
                    width: 7
                    height: 7
                    radius: 4
                    color: card.widget.running ? card.palette.green : card.palette.muted
                }

                Text {
                    text: card.widget.running ? "Running" : "Stopped"
                    color: card.palette.dark_foreground
                    font.pixelSize: 10
                }

                Text {
                    text: "· " + card.widget.category
                    color: card.palette.dark_foreground
                    font.pixelSize: 10
                }
            }
        }

        ColumnLayout {
            spacing: 4

            Button {
                text: card.isFavorite ? "★" : "☆"
                flat: true
                onClicked: card.service.toggleFavorite(card.widget.name)
            }

            Button {
                text: card.widget.running ? "↻" : "▶"
                onClicked: card.service.runAction(
                    card.widget.running ? "restart" : "launch", card.widget.name
                )
            }

            Button {
                visible: card.widget.running
                text: "■"
                onClicked: card.service.runAction("stop", card.widget.name)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 8
        visible: card.viewMode === "grid"

        WidgetPreview {
            Layout.fillWidth: true
            Layout.preferredHeight: 126
            widget: card.widget
            palette: card.palette
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: card.widget.label || card.widget.name
                    color: card.palette.foreground
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                RowLayout {
                    spacing: 5

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: card.widget.running ? card.palette.green : card.palette.muted
                    }

                    Text {
                        text: card.widget.running ? "Running" : "Stopped"
                        color: card.palette.dark_foreground
                        font.pixelSize: 10
                    }

                    Text {
                        text: "· " + card.widget.category
                        color: card.palette.dark_foreground
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }

            Button {
                text: card.isFavorite ? "★" : "☆"
                flat: true
                implicitWidth: 30
                implicitHeight: 30
                onClicked: card.service.toggleFavorite(card.widget.name)
                contentItem: Text {
                    text: parent.text
                    color: card.isFavorite ? card.palette.accent : card.palette.dark_foreground
                    font.pixelSize: 19
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Button {
                Layout.fillWidth: true
                text: card.widget.running ? "Restart" : "Launch"
                onClicked: card.service.runAction(
                    card.widget.running ? "restart" : "launch", card.widget.name
                )
            }

            Button {
                visible: card.widget.running
                text: "Stop"
                onClicked: card.service.runAction("stop", card.widget.name)
            }
        }
    }
}
