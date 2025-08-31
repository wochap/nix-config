import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

import "Utils.js" as Utils

WrapperRectangle {
  id: root

  property HyprlandMonitor monitor: Hyprland.monitorFor(QsWindow.window?.screen)
  property var workspaceId: monitor?.activeWorkspace?.id ?? 0
  property var activeWindowByWorkspaceId: Object.entries(SHyprland.workspacesById).reduce((result, [workspaceId, workspace]) => {
    return Object.assign(result, {
      [workspaceId]: SHyprland.clientsByAddress?.[workspace.lastwindow] ?? null
    });
  }, {})
  property var activeWindow: activeWindowByWorkspaceId[workspaceId]
  property bool isVisible: activeWindow ? true : false

  Layout.maximumWidth: 300 + 28
  color: "transparent"
  margin: 0
  visible: root.isVisible

  RowLayout {
    anchors.fill: parent
    spacing: (ConfigBar.modulesSpacing / 2) - 1

    SystemIcon {
      Layout.fillHeight: true
      Layout.leftMargin: -3
      icon: Utils.mapAppId(root.activeWindow?.class ?? "")
      size: ConfigBar.barHeight - ConfigBar.barPaddingY
    }

    ColumnLayout {
      Layout.fillHeight: true
      spacing: 0

      StyledText {
        Layout.fillWidth: true
        text: root.activeWindow?.class ?? ""
        font.pixelSize: Styles?.font.pixelSize.small
        elide: Text.ElideMiddle
      }
      StyledText {
        Layout.fillWidth: true
        text: root.activeWindow?.title ?? ""
        font.pixelSize: Styles?.font.pixelSize.small
        elide: Text.ElideMiddle
      }
    }
  }
}
