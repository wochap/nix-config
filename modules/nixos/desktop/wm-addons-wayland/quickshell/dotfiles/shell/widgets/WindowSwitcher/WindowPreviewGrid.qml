import QtQuick

Item {
  id: root

  required property var windows
  property real previewAspect: 16.0 / 9.0
  property string selectedId: ""
  property bool interactive: false
  property real gap: 8
  property int maxBoxWidth: 280
  property real availableWidth: 0
  readonly property real tileChromeHeight: 22
  readonly property int count: root.windows?.length ?? 0
  readonly property real boxWidth: Math.min(root.maxBoxWidth, root.availableWidth)
  readonly property real boxHeight: root.boxWidth / root.previewAspect + root.tileChromeHeight
  readonly property int perRow: Math.max(1, Math.floor((root.availableWidth + root.gap) / (root.boxWidth + root.gap)))
  readonly property int rows: root.count === 0 ? 1 : Math.ceil(root.count / root.perRow)
  readonly property real contentWidth: {
    const n = Math.min(root.count || 1, root.perRow);
    return n * root.boxWidth + root.gap * (n - 1);
  }
  readonly property real contentHeight: {
    const n = Math.max(root.rows, 1);
    return n * root.boxHeight + root.gap * (n - 1);
  }

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  signal tileClicked(string windowId)

  function tilesInRow(row) {
    return Math.max(0, Math.min(root.perRow, root.count - row * root.perRow));
  }

  function rowWidth(row) {
    const n = root.tilesInRow(row);
    return n > 0 ? n * root.boxWidth + root.gap * (n - 1) : 0;
  }

  Repeater {
    model: root.windows

    delegate: WindowSwitcherTile {
      required property int index
      required property var modelData

      readonly property int row: Math.floor(index / root.perRow)
      readonly property int column: index - row * root.perRow

      x: (root.contentWidth - root.rowWidth(row)) / 2 + column * (root.boxWidth + root.gap)
      y: row * (root.boxHeight + root.gap)
      width: root.boxWidth
      height: root.boxHeight
      previewAspect: root.previewAspect
      captureSource: modelData?.captureSource ?? null
      icon: modelData?.icon ?? ""
      title: modelData?.title ?? ""
      badge: modelData?.key ?? ""
      selected: modelData?.id === root.selectedId
      interactive: root.interactive
      onClicked: root.tileClicked(modelData?.id ?? "")
    }
  }
}
