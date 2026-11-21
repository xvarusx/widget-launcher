import Quickshell
import Quickshell.Hyprland
import QtQuick

import "services"
import "ui"

Scope {
    id: root

    WidgetService { id: widgetService }

    LauncherWindow {
        id: launcher
        service: widgetService
        visible: true
    }

    GlobalShortcut {
        appid: "widget-launcher"
        name: "toggle"
        description: "Show or hide the Quickshell widget launcher"

        onReleased: {
            if (widgetService.settings.global_shortcut_enabled)
                launcher.visible = !launcher.visible
        }
    }

    IpcHandler {
        target: "widget-launcher"

        function toggle(): void { launcher.visible = !launcher.visible }
        function show(): void { launcher.visible = true }
        function hide(): void { launcher.visible = false }
        function refresh(): void { widgetService.refresh() }
    }
}
