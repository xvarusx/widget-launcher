import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Rectangle {
    id: card

    required property var widget
    required property var service
    property string viewMode: "grid"

    readonly property var palette: service.theme

    width: viewMode === "grid" ? 218 : 1
    height: viewMode === "grid" ? 246 : 104
    radius: Number(card.palette.corner_radius || 0)
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

            ThemeSwitch {
                themePalette: card.palette
                checked: card.widget.autostart
                onToggled: card.service.runAction(
                    checked ? "autostart-enable" : "autostart-disable",
                    card.widget.name
                )
            }

            ThemedButton {
                themeColors: card.palette
                accent: true
                text: card.widget.running ? "Restart" : "Launch"
                onClicked: card.service.runAction(
                    card.widget.running ? "restart" : "launch", card.widget.name
                )
            }

            ThemedButton {
                themeColors: card.palette
                visible: card.widget.running
                text: "Stop"
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

            ColumnLayout {
                spacing: 2

                ThemeSwitch {
                    Layout.alignment: Qt.AlignRight
                    themePalette: card.palette
                    checked: card.widget.autostart
                    onToggled: card.service.runAction(
                        checked ? "autostart-enable" : "autostart-disable",
                        card.widget.name
                    )
                }

                Text {
                    text: "Auto-start"
                    color: card.palette.dark_foreground
                    font.pixelSize: 9
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            ThemedButton {
                Layout.fillWidth: true
                themeColors: card.palette
                accent: true
                text: card.widget.running ? "Restart" : "Launch"
                onClicked: card.service.runAction(
                    card.widget.running ? "restart" : "launch", card.widget.name
                )
            }

            ThemedButton {
                visible: card.widget.running
                themeColors: card.palette
                text: "Stop"
                onClicked: card.service.runAction("stop", card.widget.name)
            }
        }
    }
}
