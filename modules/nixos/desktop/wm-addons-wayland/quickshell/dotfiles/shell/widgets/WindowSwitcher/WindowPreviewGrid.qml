import QtQuick

// Tiles laid out as a single centered strip (up to `stripMax` windows) or as a
// left-aligned grid of smaller tiles. Previews are always 16:10.
Item {
  id: root

  required property var windows
  property string selectedId: ""
  property bool interactive: false
  property real availableWidth: 0
  property real gap: 8
  property int stripMax: 5
  property int gridColumns: 5
  readonly property real previewAspect: 16.0 / 10.0
  readonly property real tilePadding: 6
  // Window under the pointer, if any.
  property string hoveredId: ""

  readonly property int count: root.windows?.length ?? 0
  readonly property bool isStrip: root.count <= root.stripMax && root.fits(236, root.count)
  readonly property real tileWidth: root.isStrip ? 236 : 188
  readonly property real previewHeight: Math.round((root.tileWidth - 2 * root.tilePadding) / root.previewAspect)
  readonly property real tileHeight: 3 * root.tilePadding + root.previewHeight + 24
  readonly property int perRow: {
    const fit = Math.max(1, Math.floor((root.availableWidth + root.gap) / (root.tileWidth + root.gap)));
    return root.isStrip ? Math.max(1, root.count) : Math.min(root.gridColumns, fit);
  }
  readonly property int rows: root.count === 0 ? 0 : Math.ceil(root.count / root.perRow)
  readonly property real contentWidth: {
    const n = Math.min(root.count, root.perRow);
    return n > 0 ? n * root.tileWidth + root.gap * (n - 1) : 0;
  }
  readonly property real contentHeight: root.rows > 0 ? root.rows * root.tileHeight + root.gap * (root.rows - 1) : 0

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  signal tileClicked(string windowId)

  function fits(width, n) {
    return n * width + root.gap * Math.max(0, n - 1) <= root.availableWidth;
  }

  function rowOf(windowId) {
    for (let i = 0; i < root.count; i++) {
      if (root.windows[i]?.id === windowId)
        return Math.floor(i / root.perRow);
    }
    return -1;
  }

  Repeater {
    model: root.windows

    delegate: WindowSwitcherTile {
      id: tile

      required property int index
      required property var modelData

      readonly property int row: Math.floor(index / root.perRow)
      readonly property int column: index - row * root.perRow

      entry: modelData
      x: column * (root.tileWidth + root.gap)
      y: row * (root.tileHeight + root.gap)
      width: root.tileWidth
      height: root.tileHeight
      previewHeight: root.previewHeight
      selected: modelData?.id === root.selectedId
      interactive: root.interactive
      onClicked: root.tileClicked(modelData?.id ?? "")
      onHoveredChanged: {
        if (tile.hovered)
          root.hoveredId = modelData?.id ?? "";
        else if (root.hoveredId === (modelData?.id ?? ""))
          root.hoveredId = "";
      }
    }
  }
}
