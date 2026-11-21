import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: service

    readonly property string backend: Quickshell.shellDir + "/scripts/widgetctl.py"

    property var widgets: []
    property var settings: ({
        view_mode: "grid",
        favorites: [],
        auto_refresh_seconds: 8,
        auto_capture_previews: true,
        global_shortcut_enabled: true,
        show_favorites_first: true,
        window_opacity: 94
    })
    property var theme: ({
        background: "#171717", dark_background: "#101010",
        darker_background: "#090909", lighter_background: "#262626",
        foreground: "#f5f5f5", dark_foreground: "#a3a3a3",
        accent: "#89b4fa", selection: "#343434", muted: "#737373",
        red: "#f38ba8", green: "#a6e3a1", blue: "#89b4fa"
    })

    property bool loaded: false
    property bool scanning: false
    property string errorMessage: ""

    function refresh() {
        if (scanProcess.running)
            return
        scanning = true
        scanProcess.running = true
    }

    function updateSetting(key, value) {
        const next = Object.assign({}, settings)
        next[key] = value
        settings = next
        settingsProcess.exec(["python3", backend, "settings-set", JSON.stringify(next)])
    }

    function toggleFavorite(configName) {
        const next = Object.assign({}, settings)
        let favorites = (next.favorites || []).slice()
        const index = favorites.indexOf(configName)
        if (index >= 0) favorites.splice(index, 1)
        else favorites.push(configName)
        next.favorites = favorites
        settings = next
        settingsProcess.exec(["python3", backend, "settings-set", JSON.stringify(next)])
    }

    function runAction(action, configName) {
        actionProcess.exec(["python3", backend, action, configName])
    }

    Process {
        id: scanProcess
        command: ["python3", service.backend, "scan"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(this.text)
                    service.widgets = payload.widgets || []
                    service.settings = payload.settings || service.settings
                    service.theme = payload.theme || service.theme
                    service.errorMessage = payload.error || ""
                    service.loaded = true
                } catch (error) {
                    service.errorMessage = "Could not read widget scan results: " + error
                    console.error(service.errorMessage, this.text)
                }
                service.scanning = false
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("Widget scanner:", this.text)
            }
        }
    }

    Process {
        id: themeProcess
        command: ["python3", service.backend, "theme"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    service.theme = JSON.parse(this.text)
                } catch (error) {
                    console.warn("Theme palette response:", this.text)
                }
            }
        }
    }

    Process {
        id: actionProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text)
                    service.errorMessage = result.error || ""
                } catch (error) {
                    service.errorMessage = "Widget action failed: " + error
                }
                service.refresh()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("Widget action:", this.text)
            }
        }
    }

    Process {
        id: settingsProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text)
                    if (result.error)
                        service.errorMessage = result.error
                } catch (error) {
                    console.warn("Settings response:", this.text)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("Settings:", this.text)
            }
        }
    }

    Timer {
        interval: Math.max(2, Number(service.settings.auto_refresh_seconds || 0)) * 1000
        repeat: true
        running: service.loaded && Number(service.settings.auto_refresh_seconds || 0) > 0
        onTriggered: service.refresh()
    }

    // Palette polling is independent of widget auto-refresh so theme changes
    // are reflected even when the user disables periodic widget scanning.
    Timer {
        interval: 3000
        repeat: true
        running: service.loaded
        onTriggered: {
            if (!themeProcess.running)
                themeProcess.running = true
        }
    }

    Component.onCompleted: refresh()
}
