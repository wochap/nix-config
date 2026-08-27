import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.widgets.WindowSwitcher
import qs.widgets.common

PanelWindow {
  id: root

  required property var backend
  readonly property real panelPadding: 8
  readonly property real maxInnerWidth: Math.max(0, 0.8 * width - 2 * panelPadding)
  property var shownWindows: []
  property bool panelVisible: false
  property real fadeOpacity: 0

  function showPanel() {
    if (root.backend.windows.length === 0) {
      root.hidePanel();
      return;
    }
    root.shownWindows = root.backend.windows;
    root.panelVisible = true;
    revealTimer.restart();
  }

  function hidePanel() {
    revealTimer.stop();
    root.fadeOpacity = 0;
  }

  function syncPanel() {
    if ((root.backend.submap === "harpoon" || root.backend.submap === "scratchpad")
        && root.backend.windows.length > 0)
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
  mask: Region {}
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
    onTriggered: root.fadeOpacity = 1
  }

  Behavior on fadeOpacity {
    NumberAnimation {
      duration: 140
      easing.type: Easing.OutCubic
      onFinished: {
        if (root.fadeOpacity === 0) {
          root.panelVisible = false;
          root.shownWindows = [];
        }
      }
    }
  }

  Item {
    opacity: root.fadeOpacity
    anchors.centerIn: parent
    width: previewGrid.contentWidth + 2 * root.panelPadding
    height: previewGrid.contentHeight + 2 * root.panelPadding

    StyledRectangularShadow {
      target: panelBackground
    }

    StyledRect {
      id: panelBackground

      anchors.fill: parent
      radius: Math.round(Styles.radius.windowRounding + 6)
      color: Theme.options.backgroundOverlay
      border {
        width: 1
        color: Theme.options.borderSecondary
      }
    }

    WindowPreviewGrid {
      id: previewGrid
      x: root.panelPadding
      y: root.panelPadding
      windows: root.shownWindows
      previewAspect: root.backend.focusedMonitorAspect
      availableWidth: root.maxInnerWidth
    }
  }
}
