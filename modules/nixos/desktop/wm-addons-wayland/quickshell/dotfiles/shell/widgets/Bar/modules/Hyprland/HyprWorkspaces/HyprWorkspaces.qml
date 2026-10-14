import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.services
import "../Utils.js" as Utils

Item {
  id: root

  readonly property int workspacesShown: 9
  readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(QsWindow.window?.screen)
  readonly property list<bool> workspacesOccupied: Array.from({
    length: root.workspacesShown
  }, (_, i) => {
    return Hyprland.workspaces.values.some(workspace => workspace.id === SHyprland.wsOffset + i + 1);
  })
  readonly property int focusedIndex: (root.hyprlandMonitor?.activeWorkspace?.id ?? 0) - SHyprland.wsOffset - 1
  // re-evaluated when the repeater creates its delegates
  readonly property Item focusedItem: repeater.count > 0 ? repeater.itemAt(root.focusedIndex) : null
  readonly property var clientsByWorkspaceId: {
    const result = Object.entries(SHyprland.workspacesById).reduce((result, [workspaceId, workspace]) => {
      const clients = (SHyprland.clientsByWorkspaceId?.[workspace.id] ?? []).map(client => (Object.assign(client, {
            isFocused: client.address === SHyprland.activeWindow?.address,
            customClass: Utils.mapAppId(client.class)
          }))).filter(client => !Utils.isIgnoredInWorkspaces(client.customClass, client.title)).sort(Utils.compareOpenOrder);
      return Object.assign(result, {
        [workspace.id]: clients
      });
    }, {});
    return result;
  }

  Component.onCompleted: {
    Quickshell.execDetached(["bash", "-c", `hyprctl eval 'require("hyprland.lib.ws_offset").emit()'`]);
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  // unfocused backgrounds, drawn here so the indicator can slide above them
  // and below the workspace contents
  Repeater {
    model: repeater.count

    delegate: StyledRect {
      required property int index
      readonly property Item item: repeater.itemAt(index)

      x: item?.x ?? 0
      width: item?.width ?? 0
      height: root.height
      color: Theme.options.base
      radius: ConfigBar.modulesRadius
    }
  }

  // focused background, moves to the active workspace and follows its width
  // while it morphs between the number and the taskbar
  StyledRect {
    id: indicator

    x: root.focusedItem?.x ?? 0
    width: root.focusedItem?.width ?? 0
    height: root.height
    opacity: root.focusedItem ? 1 : 0
    color: Theme.options.surface0
    radius: ConfigBar.modulesRadius

    // x retargets while the workspaces before it morph, the width needs no
    // animation, the focused workspace already animates its own width
    Behavior on x {
      animation: Styles.animations.smoothedAnimation.createObject(this)
    }

    Behavior on opacity {
      animation: Styles.animations.numberAnimation.createObject(this)
    }
  }

  RowLayout {
    id: row

    anchors.fill: parent
    spacing: ConfigBar.modulesSpacing

    Repeater {
      id: repeater

      model: root.workspacesShown
      delegate: HyprWorkspace {
        Layout.fillHeight: true
        clients: root.clientsByWorkspaceId?.[SHyprland.wsOffset + index + 1] ?? []
        workspace: SHyprland.workspacesById[SHyprland.wsOffset + index + 1]
        isOccupied: root.workspacesOccupied?.[index] ?? true
        hyprlandMonitor: root.hyprlandMonitor
      }
    }
  }
}
