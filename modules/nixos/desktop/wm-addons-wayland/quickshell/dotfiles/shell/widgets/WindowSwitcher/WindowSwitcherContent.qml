import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

PanelWindow {
  id: root

  required property var backend

  readonly property real screenPadding: 64
  readonly property real panelPadding: 8

  // Switcher only ever operates on the focused monitor, so every preview uses
  // that monitor's aspect ratio.
  readonly property real previewAspect: root.backend.focusedMonitorAspect

  readonly property var toplevels: root.backend.windows
  readonly property real maxInnerWidth: Math.max(0, 0.8 * root.width - 2 * root.panelPadding)

  WlrLayershell.namespace: "quickshell:window-switcher"
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

  // Transparent background. Invisible full-screen click catcher: clicking
  // anywhere outside the panel closes the switcher.
  MouseArea {
    id: backdrop
    anchors.fill: parent
    onClicked: root.backend.hide()
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

  // Centered panel that hugs the grid of window previews.
  Item {
    id: panel
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
      windows: root.toplevels
      previewAspect: root.previewAspect
      availableWidth: root.maxInnerWidth
      selectedId: root.backend.selectedId
      interactive: true
      onTileClicked: windowId => {
        root.backend.select(windowId);
        root.backend.confirm();
      }
    }
  }
}
