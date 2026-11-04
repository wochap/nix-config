import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.VBar.config
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

  onFocusedItemChanged: {
    if (root.focusedItem && indicator.lastFocusedItem) {
      indicator.isSliding = true;
    }
    indicator.lastFocusedItem = root.focusedItem;
  }

  Component.onCompleted: {
    Quickshell.execDetached(["bash", "-c", `hyprctl eval 'require("hyprland.lib.ws_offset").emit()'`]);
  }

  implicitWidth: 36
  implicitHeight: col.implicitHeight

  // Unfocused workspace backgrounds
  Repeater {
    model: repeater.count

    delegate: StyledRect {
      required property int index
      readonly property Item item: repeater.itemAt(index)

      x: 0
      y: item?.y ?? 0
      width: root.width
      height: item?.height ?? 0
      color: Theme.options.base
      radius: ConfigVBar.modulesRadius
    }
  }

  // Sliding focused indicator
  StyledRect {
    id: indicator

    x: 0
    y: root.focusedItem?.y ?? 0
    width: root.width
    height: root.focusedItem?.height ?? 0
    opacity: root.focusedItem ? 1 : 0
    property bool isSliding: false
    property Item lastFocusedItem: null
    color: Theme.options.surface0
    radius: ConfigVBar.modulesRadius

    Behavior on y {
      enabled: indicator.isSliding
      animation: Styles.animations.smoothedAnimation.createObject(this)
    }

    Behavior on height {
      animation: Styles.animations.smoothedAnimation.createObject(this)
    }

    Behavior on opacity {
      animation: Styles.animations.numberAnimation.createObject(this)
    }
  }

  ColumnLayout {
    id: col

    anchors.fill: parent
    spacing: ConfigVBar.modulesSpacing

    Repeater {
      id: repeater

      model: root.workspacesShown
      delegate: VHyprWorkspace {
        Layout.fillWidth: true
        clients: root.clientsByWorkspaceId?.[SHyprland.wsOffset + index + 1] ?? []
        workspace: SHyprland.workspacesById[SHyprland.wsOffset + index + 1]
        isOccupied: root.workspacesOccupied?.[index] ?? true
        hyprlandMonitor: root.hyprlandMonitor
      }
    }
  }
}
