import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog

    required property var service
    readonly property var palette: service.theme

    modal: true
    title: "Launcher settings"
    standardButtons: Dialog.Close
    width: Math.min(500, parent ? parent.width - 32 : 500)

    background: Rectangle {
        color: dialog.palette.background
        radius: Number(window.palette.corner_radius || 0)
        border.width: 1
        border.color: dialog.palette.muted
    }

    header: Label {
        text: "Settings"
        color: dialog.palette.foreground
        font.pixelSize: 20
        font.weight: Font.DemiBold
        padding: 20
        bottomPadding: 4
    }

    contentItem: Flickable {
        implicitHeight: Math.min(settingsColumn.implicitHeight, 480)
        contentHeight: settingsColumn.implicitHeight
        clip: true

        ColumnLayout {
            id: settingsColumn
            width: parent.width
            spacing: 15

            Label {
                text: "Appearance"
                color: dialog.palette.accent
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: "Widget layout"
                    color: dialog.palette.foreground
                }

                ComboBox {
                    model: ["Grid", "List"]
                    currentIndex: dialog.service.settings.view_mode === "list" ? 1 : 0
                    onActivated: dialog.service.updateSetting(
                        "view_mode", currentIndex === 1 ? "list" : "grid"
                    )
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: "Window opacity"
                    color: dialog.palette.foreground
                }

                Slider {
                    id: opacitySlider
                    from: 70
                    to: 100
                    stepSize: 1
                    value: Number(dialog.service.settings.window_opacity || 94)
                    onMoved: dialog.service.updateSetting("window_opacity", Math.round(value))
                }

                Label {
                    text: Math.round(opacitySlider.value) + "%"
                    color: dialog.palette.dark_foreground
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: dialog.palette.muted
            }

            Label {
                text: "Behavior"
                color: dialog.palette.accent
                font.weight: Font.DemiBold
            }

            CheckBox {
                text: "Capture previews for running widgets"
                checked: dialog.service.settings.auto_capture_previews
                onToggled: dialog.service.updateSetting("auto_capture_previews", checked)
            }

            CheckBox {
                text: "Show favorites first"
                checked: dialog.service.settings.show_favorites_first
                onToggled: dialog.service.updateSetting("show_favorites_first", checked)
            }

            CheckBox {
                text: "Enable global shortcut"
                checked: dialog.service.settings.global_shortcut_enabled
                onToggled: dialog.service.updateSetting("global_shortcut_enabled", checked)
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: "Auto-refresh interval"
                    color: dialog.palette.foreground
                }

                ComboBox {
                    model: ["Off", "5 seconds", "8 seconds", "15 seconds", "30 seconds"]
                    currentIndex: {
                        const value = Number(dialog.service.settings.auto_refresh_seconds)
                        if (value === 0) return 0
                        if (value <= 5) return 1
                        if (value <= 8) return 2
                        if (value <= 15) return 3
                        return 4
                    }
                    onActivated: {
                        const values = [0, 5, 8, 15, 30]
                        dialog.service.updateSetting("auto_refresh_seconds", values[currentIndex])
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Colors follow Omarchy's active theme. The global shortcut also needs a Hyprland bind; see the README."
                color: dialog.palette.dark_foreground
                font.pixelSize: 11
            }
        }
    }
}
