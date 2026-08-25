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
  readonly property real gap: 8
  // Space below the preview: layout spacing and caption.
  readonly property real tileChromeHeight: 22
  readonly property int maxColumns: 5
  readonly property int maxBoxWidth: 280

  // Switcher only ever operates on the focused monitor, so every preview uses
  // that monitor's aspect ratio.
  readonly property real previewAspect: root.backend.focusedMonitorAspect

  readonly property var toplevels: root.backend.windows
  readonly property int count: root.toplevels?.length ?? 0

  // Boxes keep a small, fixed size; the panel caps at ~80% of the monitor,
  // wraps overflow onto new rows, and centers every row horizontally.
  readonly property real maxInnerWidth: Math.max(0, 0.8 * root.width - 2 * root.panelPadding)
  readonly property real boxWidth: Math.min(root.maxBoxWidth, root.maxInnerWidth)
  readonly property real boxHeight: root.boxWidth / root.previewAspect + root.tileChromeHeight
  readonly property int perRow: Math.max(1, Math.floor((root.maxInnerWidth + root.gap) / (root.boxWidth + root.gap)))
  readonly property int rows: root.count === 0 ? 1 : Math.ceil(root.count / root.perRow)
  readonly property real innerWidth: {
    const n = Math.min(root.count || 1, root.perRow);
    return n * root.boxWidth + root.gap * (n - 1);
  }
  readonly property real innerHeight: {
    const n = Math.max(root.rows, 1);
    return n * root.boxHeight + root.gap * (n - 1);
  }
  readonly property real panelWidth: root.innerWidth + 2 * root.panelPadding
  readonly property real panelHeight: root.innerHeight + 2 * root.panelPadding

  function tilesInRow(row) {
    return Math.max(0, Math.min(root.perRow, root.count - row * root.perRow));
  }
  function rowWidth(row) {
    const n = root.tilesInRow(row);
    return n > 0 ? n * root.boxWidth + root.gap * (n - 1) : 0;
  }
  function tileX(index) {
    const row = Math.floor(index / root.perRow);
    const col = index - row * root.perRow;
    return (root.innerWidth - root.rowWidth(row)) / 2 + col * (root.boxWidth + root.gap);
  }
  function tileY(index) {
    return Math.floor(index / root.perRow) * (root.boxHeight + root.gap);
  }

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
    width: root.panelWidth
    height: root.panelHeight

    StyledRect {
      anchors.fill: parent
      radius: Math.round(Styles.radius.windowRounding + 6)
      color: Theme.options.backgroundOverlay
      border {
        width: 1
        color: Theme.options.borderSecondary
      }
    }

    // Window tiles, wrapped into rows, every row centered horizontally.
    Item {
      x: root.panelPadding
      y: root.panelPadding
      width: root.innerWidth
      height: root.innerHeight

      Repeater {
        model: root.toplevels

        delegate: WindowSwitcherTile {
          x: root.tileX(index)
          y: root.tileY(index)
          width: root.boxWidth
          height: root.boxHeight
          previewAspect: root.previewAspect
          captureSource: modelData?.captureSource ?? null
          icon: modelData?.icon ?? ""
          title: modelData?.title ?? ""
          selected: modelData?.id === root.backend.selectedId
          onClicked: {
            root.backend.select(modelData?.id ?? "");
            root.backend.confirm();
          }
        }
      }
    }
  }
}
