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

Item {
  id: root

  property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(QsWindow.window?.screen)
  property var workspaceId: hyprlandMonitor?.activeWorkspace?.id ?? 0
  property var activeWindowByWorkspaceId: Object.entries(SHyprland.workspacesById).reduce((result, [workspaceId, workspace]) => {
    return Object.assign(result, {
      [workspaceId]: SHyprland.clientsByAddress?.[workspace.lastwindow] ?? null
    });
  }, {})
  property var activeWindow: activeWindowByWorkspaceId[workspaceId]
  property bool isVisible: activeWindow ? true : false
  readonly property string appId: root.activeWindow?.class ?? ""
  readonly property string title: root.activeWindow?.title ?? ""

  Layout.maximumWidth: 300 + 28
  implicitWidth: Math.min(row.implicitWidth, 300 + 28)
  implicitHeight: row.implicitHeight
  visible: root.isVisible

  HoverHandler {
    id: hoverHandler

    onHoveredChanged: {
      if (hovered) {
        tooltipTimer.restart();
      } else {
        tooltipTimer.stop();
        tooltip.shown = false;
      }
    }
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: `Focused window: ${root.title || root.appId}`
    Accessible.onPressAction: focusActive()
    onClicked: {
      tooltip.shown = false;
      focusActive();
    }

    function focusActive() {
      if (!root.activeWindow?.address) return;
      const window = `"address:${root.activeWindow.address}"`;
      const raise = root.activeWindow.floating ? `hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = ${window} }))` : "";
      Quickshell.execDetached(["hyprctl", "eval", `
        local no_warps = hl.get_config("cursor.no_warps")
        hl.config({ cursor = { no_warps = true } })
        hl.dispatch(hl.dsp.focus({ window = ${window} }))
        ${raise}
        hl.config({ cursor = { no_warps = no_warps } })
      `]);
    }
  }

  Timer {
    id: tooltipTimer

    interval: 350
    onTriggered: tooltip.shown = root.title.length > 0
  }

  WindowTooltip {
    id: tooltip

    anchor.item: root
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.margins.left: -16
    anchor.margins.top: -2
    anchor.margins.bottom: 0
    icon: Utils.mapAppId(root.appId)
    appId: root.appId
    title: root.title
  }

  RowLayout {
    id: row

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
        font.pixelSize: Styles.font.pixelSize.small
        font.weight: 600
        color: Theme.options.primary
        elide: Text.ElideMiddle
      }
      StyledText {
        Layout.fillWidth: true
        text: root.activeWindow?.title ?? ""
        font.pixelSize: Styles.font.pixelSize.small
        font.weight: 500
        color: Theme.options.subtext0
        elide: Text.ElideMiddle
      }
    }
  }
}
