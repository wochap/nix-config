import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.widgets.WindowSwitcher
import qs.widgets.common

PanelWindow {
  id: root

  required property var backend
  readonly property real maxInnerWidth: Math.max(0, 0.8 * width - 2 * panel.padding)
  readonly property bool isScratchpad: root.shownSubmap === "scratchpad"
  property var shownWindows: []
  property string shownSubmap: ""
  property bool panelVisible: false
  property real fadeOpacity: 0
  readonly property var hoveredEntry: {
    for (const entry of root.shownWindows) {
      if (entry?.id === previewGrid.hoveredId)
        return entry;
    }
    return null;
  }

  function showPanel() {
    root.shownWindows = root.backend.windows;
    root.shownSubmap = root.backend.submap;
    root.panelVisible = true;
    fadeAnimation.stop();
    revealTimer.restart();
  }

  function hidePanel() {
    revealTimer.stop();
    fadeAnimation.to = 0;
    fadeAnimation.restart();
  }

  function syncPanel() {
    if (root.backend.isOpen)
      root.showPanel();
    else
      root.hidePanel();
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0
  color: "transparent"
  // Only the panel takes pointer input; the rest of the screen stays usable.
  // Keyboard input stays with the compositor's harpoon submap.
  mask: Region {
    item: panel
  }
  visible: panelVisible
  WlrLayershell.namespace: "quickshell:harpoon"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  Component.onCompleted: {
    syncTimer.restart();
  }

  Connections {
    target: root.backend

    function onWindowsChanged() {
      syncTimer.restart();
    }

    function onSubmapChanged() {
      syncTimer.restart();
    }
  }

  // Submap and model bindings can notify in either order. Coalesce their
  // changes and inspect the settled backend state once on the next event turn.
  Timer {
    id: syncTimer
    interval: 0
    onTriggered: root.syncPanel()
  }

  Timer {
    id: revealTimer
    interval: 34
    onTriggered: {
      fadeAnimation.to = 1;
      fadeAnimation.restart();
    }
  }

  // Standalone on purpose: Qt never emits finished for an animation inside a
  // Behavior, which left the invisible panel mapped and its mask swallowing
  // clicks at the center of the screen.
  NumberAnimation {
    id: fadeAnimation

    target: root
    property: "fadeOpacity"
    duration: Styles.animation.duration
    easing.type: Styles.animation.easingType
    onFinished: {
      if (root.fadeOpacity === 0) {
        root.panelVisible = false;
        root.shownWindows = [];
      }
    }
  }

  SwitcherPanel {
    id: panel

    anchors.centerIn: parent
    opacity: root.fadeOpacity

    WindowPreviewGrid {
      id: previewGrid

      visible: root.shownWindows.length > 0
      windows: root.shownWindows
      availableWidth: root.maxInnerWidth
      interactive: true
      onTileClicked: windowId => {
        const entry = root.shownWindows.find(candidate => candidate?.id === windowId);
        if (entry?.key)
          root.backend.focus(entry.key);
      }
    }

    WindowSwitcherDetail {
      visible: root.shownWindows.length > 0
      width: previewGrid.contentWidth
      entry: root.hoveredEntry
      meta: {
        const n = root.shownWindows.length;
        const count = `${n} ${root.isScratchpad ? "scratchpad" : "window"}${n === 1 ? "" : "s"}`;
        const entry = root.hoveredEntry;
        return entry ? [entry.appClass, `ws ${entry.workspace}`, count].filter(part => part.length > 0).join(" · ") : count;
      }
      placeholder: "Click or press a key to focus"
    }

    WindowSwitcherEmpty {
      visible: root.shownWindows.length === 0
      title: root.isScratchpad ? "No scratchpads marked" : "No windows marked"
      hint: "Shift+key marks the active window · Esc exits"
    }
  }
}
