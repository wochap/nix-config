import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config
import qs.widgets.Bar.config
import "../../../common/HyprUtils.js" as Utils
import qs.Woints

Item {
  id: root

  property bool isFocused: true
  property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(QsWindow.window?.screen)
  property var workspaceId: hyprlandMonitor?.activeWorkspace?.id ?? 0
  property var activeWindowByWorkspaceId: Object.entries(SHyprland.workspacesById).reduce((result, [workspaceId, workspace]) => {
    return Object.assign(result, {
      [workspaceId]: SHyprland.clientsByAddress?.[workspace.lastwindow] ?? null
    });
  }, {})
  property var activeWindow: activeWindowByWorkspaceId[workspaceId]
  property bool isVisible: !!activeWindow
  readonly property string appId: root.activeWindow?.class ?? ""
  readonly property string title: root.activeWindow?.title ?? ""

  property int maxAppIdLength: 10
  property int maxTitleLength: 18

  function truncateMiddle(str, maxLen) {
    if (!str) return "";
    if (str.length <= maxLen) return str;
    const keep = Math.max(1, maxLen - 3);
    const left = Math.ceil(keep / 2);
    const right = Math.floor(keep / 2);
    return str.substring(0, left) + "..." + str.substring(str.length - right);
  }

  visible: isVisible
  implicitWidth: 36
  implicitHeight: col.implicitHeight

  ColumnLayout {
    id: col

    anchors.centerIn: parent
    spacing: 4
    width: parent.width

    SystemIcon {
      Layout.alignment: Qt.AlignHCenter
      icon: Utils.mapAppId(root.appId)
      size: ConfigBar.barHeight - ConfigBar.barPaddingY
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 3

      Item {
        id: appTextWrapper

        Layout.alignment: Qt.AlignTop
        implicitWidth: appText.implicitHeight
        implicitHeight: appText.implicitWidth
        visible: root.appId.length > 0

        StyledText {
          id: appText

          anchors.centerIn: parent
          rotation: 270
          text: root.truncateMiddle(root.appId, root.maxAppIdLength)
          font.pixelSize: Styles.font.pixelSize.small
          font.weight: 600
          color: Theme.options.primary
          horizontalAlignment: Text.AlignRight
        }
      }

      Item {
        id: titleTextWrapper

        Layout.alignment: Qt.AlignTop
        implicitWidth: titleText.implicitHeight
        implicitHeight: titleText.implicitWidth
        visible: root.title.length > 0

        StyledText {
          id: titleText

          anchors.centerIn: parent
          rotation: 270
          text: root.truncateMiddle(root.title, root.maxTitleLength)
          font.pixelSize: Styles.font.pixelSize.small
          font.weight: 500
          color: Theme.options.subtext0
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }

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
    onClicked: focusActive()

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

    Hintable {
      label: root.title || root.appId || "Focused window"
      onActivated: mouseArea.focusActive()
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
    anchor.edges: Edges.Right | Edges.Top
    anchor.gravity: Edges.Right | Edges.Bottom
    anchor.margins.right: 6
    anchor.margins.top: -(Math.round((tooltip.bubbleHeight - (ConfigBar.barHeight - ConfigBar.barPaddingY)) / 2) + 12)
    icon: Utils.mapAppId(root.appId)
    appId: root.appId
    title: root.title
  }
}
