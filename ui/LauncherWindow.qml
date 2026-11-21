import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

PanelWindow {
    id: window

    required property var service
    readonly property var palette: service.theme

    // Full-screen transparent layer surface; only the centered card is visible.
    // This behaves like Omarchy's keybindings/app-launcher overlays, not a
    // normal maximizable application window.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    aboveWindows: true
    focusable: true
    color: "transparent"

    property string searchText: ""
    property string activeCategory: "All"

    function categories() {
        let values = ["All", "Favorites", "System", "Media", "Productivity",
                      "Appearance", "Development", "Other"]
        service.widgets.forEach(function(widget) {
            if (widget.category && values.indexOf(widget.category) < 0)
                values.push(widget.category)
        })
        return values
    }

    function filteredWidgets() {
        const needle = searchText.trim().toLowerCase()
        let result = service.widgets.filter(function(widget) {
            const matchesText = !needle ||
                widget.name.toLowerCase().includes(needle) ||
                (widget.label || "").toLowerCase().includes(needle) ||
                (widget.description || "").toLowerCase().includes(needle) ||
                (widget.category || "").toLowerCase().includes(needle)

            const matchesCategory = activeCategory === "All" ||
                (activeCategory === "Favorites"
                    ? (service.settings.favorites || []).indexOf(widget.name) >= 0
                    : widget.category === activeCategory)

            return matchesText && matchesCategory
        })

        if (service.settings.show_favorites_first) {
            result.sort(function(a, b) {
                const favorites = service.settings.favorites || []
                return Number(favorites.indexOf(b.name) >= 0) -
                       Number(favorites.indexOf(a.name) >= 0)
            })
        }
        return result
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: window.visible = false

        MouseArea {
            anchors.fill: parent
            onClicked: window.visible = false
        }

        Rectangle {
        id: launcherCard
        anchors.centerIn: parent
        width: Math.min(1080, parent.width - 64)
        height: Math.min(760, parent.height - 64)
        radius: Number(window.palette.corner_radius || 0)
        color: Qt.rgba(
            window.palette.background.r,
            window.palette.background.g,
            window.palette.background.b,
            Number(window.service.settings.window_opacity || 94) / 100
        )
        border.width: 1
        border.color: window.palette.muted
        z: 1

        // Keep clicks inside the launcher from reaching the outside-to-close area.
        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 3

                    Label {
                        text: "Widget Library"
                        color: window.palette.foreground
                        font.pixelSize: 25
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: "Your Quickshell widgets, in one place"
                        color: window.palette.dark_foreground
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: window.service.widgets.length + " widgets"
                    color: window.palette.dark_foreground
                    font.pixelSize: 11
                }

                ThemedButton {
                    themeColors: window.palette
                    text: "Settings"
                    onClicked: settingsDialog.open()
                }

                ThemedButton {
                    themeColors: window.palette
                    text: window.service.scanning ? "Scanning…" : "Refresh"
                    enabled: !window.service.scanning
                    onClicked: window.service.refresh()
                }
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                implicitHeight: 44
                placeholderText: "Search by widget name, category or description…"
                text: window.searchText
                onTextChanged: window.searchText = text
                color: window.palette.foreground
                placeholderTextColor: window.palette.dark_foreground
                leftPadding: 14
                background: Rectangle {
                    radius: 10
                    color: window.palette.dark_background
                    border.width: searchField.activeFocus ? 2 : 1
                    border.color: searchField.activeFocus
                        ? window.palette.accent : window.palette.muted
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                contentWidth: categoryRow.implicitWidth
                contentHeight: height
                clip: true

                Row {
                    id: categoryRow
                    spacing: 7

                    Repeater {
                        model: window.categories()

                        delegate: CategoryChip {
                            required property string modelData
                            text: modelData
                            themePalette: window.palette
                            selected: window.activeCategory === modelData
                            onClicked: window.activeCategory = modelData
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: window.filteredWidgets().length + " RESULTS"
                    color: window.palette.dark_foreground
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "OMARCHY THEME"
                    color: window.palette.accent
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: window.service.settings.view_mode === "list" ? 1 : 0

                GridView {
                    id: gridView
                    clip: true
                    cellWidth: 232
                    cellHeight: 260
                    model: window.filteredWidgets()

                    ScrollBar.vertical: ScrollBar {}

                    delegate: WidgetCard {
                        required property var modelData
                        widget: modelData
                        service: window.service
                        viewMode: "grid"
                    }
                }

                ListView {
                    id: listView
                    clip: true
                    spacing: 8
                    model: window.filteredWidgets()

                    ScrollBar.vertical: ScrollBar {}

                    delegate: WidgetCard {
                        required property var modelData
                        width: listView.width - 12
                        widget: modelData
                        service: window.service
                        viewMode: "list"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: window.service.errorMessage ||
                          (window.service.scanning ? "Refreshing widget list…" :
                           "Widget directory: ~/.config/quickshell/")
                    color: window.service.errorMessage.length > 0
                        ? window.palette.red : window.palette.dark_foreground
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }
        }
    }

    SettingsDialog {
        id: settingsDialog
        service: window.service
        anchors.centerIn: parent
    }

    Component.onCompleted: searchField.forceActiveFocus()
}
