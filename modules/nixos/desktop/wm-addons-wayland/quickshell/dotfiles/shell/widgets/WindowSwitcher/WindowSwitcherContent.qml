import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.widgets.common

PanelWindow {
  id: root

  required property var backend

  readonly property var toplevels: root.backend.windows
  readonly property real maxInnerWidth: Math.max(0, 0.8 * root.width - 2 * panel.padding)
  readonly property var selectedEntry: {
    for (const entry of root.toplevels) {
      if (entry?.id === root.backend.selectedId)
        return entry;
    }
    return null;
  }
  readonly property string countText: {
    const n = root.toplevels.length;
    const order = root.backend.order === "stable" ? "open order" : "MRU order";
    return `${n} window${n === 1 ? "" : "s"} · ${order}`;
  }
  readonly property string detailMeta: {
    const entry = root.selectedEntry;
    if (!entry)
      return root.countText;
    const parts = [entry.appClass, `ws ${entry.workspace}`];
    if (!previewGrid.isStrip)
      parts.push(`row ${previewGrid.rowOf(entry.id) + 1}/${previewGrid.rows}`);
    parts.push(root.countText);
    return parts.filter(part => part.length > 0).join(" · ");
  }

  WlrLayershell.namespace: "quickshell:window-switcher"
  // read by qs.Woints SHints, the attached WlrLayershell is not reachable from JS
  readonly property string namespace: WlrLayershell.namespace
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  color: "transparent"

  // Scrim: crust @ 60%. Clicking anywhere outside the panel closes the switcher.
  Rectangle {
    anchors.fill: parent
    color: Theme.addAlpha(Theme.options.crust, 0.6)

    MouseArea {
      anchors.fill: parent
      onClicked: root.backend.hide()
    }
  }

  // Esc cancels and Enter confirms. Modifier release is handled only by the
  // compositor binding so a single gesture cannot send duplicate confirms.
  Item {
    id: keyCatcher
    anchors.fill: parent
    focus: true
    Keys.onPressed: event => {
      if (event.key === Qt.Key_Escape) {
        event.accepted = true;
        root.backend.hide();
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        event.accepted = true;
        root.backend.confirm();
      }
    }
    Component.onCompleted: forceActiveFocus()
  }

  SwitcherPanel {
    id: panel

    anchors.centerIn: parent

    WindowPreviewGrid {
      id: previewGrid

      windows: root.toplevels
      availableWidth: root.maxInnerWidth
      selectedId: root.backend.selectedId
      interactive: true
      onTileClicked: windowId => {
        root.backend.select(windowId);
        root.backend.confirm();
      }
    }

    WindowSwitcherDetail {
      width: previewGrid.contentWidth
      entry: root.selectedEntry
      meta: root.detailMeta
    }
  }
}
