

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FloatingWindow {
    id: root

    title: "Widget Launcher"

    implicitWidth: 920
    implicitHeight: 700

    minimumSize: Qt.size(640, 480)

    color: "#0b0f14"

    property var widgets: []
    property var filteredWidgets: []
    property bool scanning: false

    // ----------------------------------------
    // Widget discovery
    // ----------------------------------------

    function loadWidgets(output) {
        let lines = output.trim().split("\n")
        let result = []

        for (let i = 0; i < lines.length; i++) {
            if (lines[i].trim() === "")
                continue

            let columns = lines[i].split("\t")

            if (columns.length < 3)
                continue

            result.push({
                name: columns[0],
                path: columns[1],
                preview: columns[2]
            })
        }

        root.widgets = result
        root.applyFilter(searchField.text)
        root.scanning = false

        console.log("Discovered", result.length, "widgets")
    }

    // ----------------------------------------
    // Search
    // ----------------------------------------

    function applyFilter(query) {
        let needle = query.trim().toLowerCase()
        let result = []

        for (let i = 0; i < root.widgets.length; i++) {
            let widget = root.widgets[i]

            if (
                widget.name.toLowerCase().includes(needle) ||
                widget.path.toLowerCase().includes(needle)
            ) {
                result.push(widget)
            }
        }

        root.filteredWidgets = result
    }

    // ----------------------------------------
    // Launch selected widget
    // ----------------------------------------

    function launchWidget(configName) {
        console.log("Launching:", configName)

        Quickshell.execDetached([
            "qs",
            "-c",
            configName
        ])
    }

    // ----------------------------------------
    // Refresh
    // ----------------------------------------

    function refresh() {
        root.scanning = true

        scanner.exec([
            "bash",
            Quickshell.shellDir + "/scan-widgets.sh"
        ])
    }

    Process {
        id: scanner

        command: [
            "bash",
            Quickshell.shellDir + "/scan-widgets.sh"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.loadWidgets(this.text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0)
                    console.warn("Scanner:", this.text)
            }
        }
    }

    // ========================================
    // USER INTERFACE
    // ========================================

    Rectangle {
        anchors.fill: parent

        color: "#0b0f14"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26

            spacing: 18

            // --------------------------------
            // Header
            // --------------------------------

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 4

                    Text {
                        text: "Widget Library"

                        color: "#f1f5f9"

                        font.pixelSize: 27
                        font.bold: true
                    }

                    Text {
                        text: "Discover and launch your Quickshell widgets"

                        color: "#8793a3"
                        font.pixelSize: 12
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "QUICKSHELL"

                    color: "#718096"

                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2
                }
            }

            // --------------------------------
            // Search and refresh
            // --------------------------------

            RowLayout {
                Layout.fillWidth: true

                spacing: 10

                TextField {
                    id: searchField

                    Layout.fillWidth: true

                    implicitHeight: 46

                    placeholderText: "Search widgets..."
                    color: "#f1f5f9"

                    font.pixelSize: 14

                    leftPadding: 16
                    rightPadding: 16

                    selectByMouse: true

                    onTextChanged: {
                        root.applyFilter(text)
                    }

                    background: Rectangle {
                        radius: 10

                        color: "#171d26"

                        border.width: 1
                        border.color: searchField.activeFocus
                            ? "#64748b"
                            : "#293241"
                    }
                }

                Rectangle {
                    implicitWidth: 108
                    implicitHeight: 46

                    radius: 10

                    color: refreshMouse.containsMouse
                        ? "#354052"
                        : "#222b38"

                    opacity: root.scanning ? 0.5 : 1

                    Text {
                        anchors.centerIn: parent

                        text: root.scanning
                            ? "Scanning..."
                            : "↻ Refresh"

                        color: "#e2e8f0"

                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        id: refreshMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape: Qt.PointingHandCursor

                        enabled: !root.scanning

                        onClicked: root.refresh()
                    }
                }
            }

            // --------------------------------
            // Widget count
            // --------------------------------

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.filteredWidgets.length
                        + " WIDGETS"

                    color: "#8c9bad"

                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "PNG  ·  WEBP  ·  SVG"

                    color: "#657386"

                    font.pixelSize: 10
                }
            }

            // --------------------------------
            // Widget gallery
            // --------------------------------

            GridView {
                id: widgetGrid

                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true

                cellWidth: 220
                cellHeight: 190

                model: root.filteredWidgets

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Item {
                    id: widgetDelegate

                    required property var modelData

                    width: widgetGrid.cellWidth
                    height: widgetGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent

                        anchors.margins: 7

                        radius: 14

                        color: cardMouse.containsMouse
                            ? "#252e3b"
                            : "#171e28"

                        border.width: 1

                        border.color: cardMouse.containsMouse
                            ? "#56657a"
                            : "#283342"

                        ColumnLayout {
                            anchors.fill: parent

                            anchors.margins: 12

                            spacing: 9

                            // Preview container

                            Rectangle {
                                Layout.fillWidth: true

                                Layout.preferredHeight: 105

                                radius: 9

                                color: "#0e141c"

                                clip: true

                                Image {
                                    anchors.fill: parent

                                    anchors.margins: 5

                                    source: widgetDelegate.modelData.preview !== ""
                                        ? "file://" + widgetDelegate.modelData.preview
                                        : ""

                                    visible: widgetDelegate.modelData.preview !== ""

                                    asynchronous: true
                                    cache: true

                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.centerIn: parent

                                    visible: widgetDelegate.modelData.preview === ""

                                    text: "▦"

                                    color: "#718096"

                                    font.pixelSize: 42
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom

                                    anchors.margins: 7

                                    visible: widgetDelegate.modelData.preview === ""

                                    text: "NO PREVIEW"

                                    color: "#64748b"

                                    font.pixelSize: 8
                                    font.bold: true
                                }
                            }

                            // Widget information

                            RowLayout {
                                Layout.fillWidth: true

                                spacing: 5

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    spacing: 3

                                    Text {
                                        Layout.fillWidth: true

                                        text: widgetDelegate.modelData.name

                                        color: "#edf2f7"

                                        font.pixelSize: 13
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true

                                        text: "Quickshell widget"

                                        color: "#8492a6"

                                        font.pixelSize: 10

                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    text: "↗"

                                    color: "#94a3b8"

                                    font.pixelSize: 18
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.launchWidget(
                                    widgetDelegate.modelData.name
                                )
                            }
                        }
                    }
                }
            }

            // --------------------------------
            // Empty state
            // --------------------------------

            Text {
                Layout.fillWidth: true

                Layout.alignment: Qt.AlignHCenter

                visible: root.filteredWidgets.length === 0

                text: root.scanning
                    ? "Scanning your widget directory..."
                    : root.widgets.length === 0
                        ? "No widgets found. Add a widget folder containing shell.qml."
                        : "No widgets match your search."

                color: "#8793a3"

                font.pixelSize: 13

                horizontalAlignment: Text.AlignHCenter
            }

            // --------------------------------
            // Footer
            // --------------------------------

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "~/.config/quickshell/"

                    color: "#64748b"

                    font.pixelSize: 10
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "WIDGET MANAGER"

                    color: "#64748b"

                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
            }
        }
    }

    Component.onCompleted: {
        searchField.forceActiveFocus()
    }
}
