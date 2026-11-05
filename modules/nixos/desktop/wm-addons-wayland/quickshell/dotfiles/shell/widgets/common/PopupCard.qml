import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

// Bar popover shell: transparent PopupWindow with a 12px shadow gutter around a
// base · 1px surface0 · r8 · p8 card. Children are stacked in the card column.
// Callers configure `anchor.*` for their bar orientation.
PopupWindow {
  id: root

  default property alias content: cardCol.data
  property bool isOpen: false
  property real minCardWidth: 108
  property real cardSpacing: 4
  // Focus the card so Escape closes the popup
  property bool closeOnEscape: false

  function toggle() {
    root.isOpen = !root.isOpen;
  }

  visible: root.isOpen
  onVisibleChanged: {
    if (!root.visible) {
      root.isOpen = false;
    }
  }

  implicitWidth: popupCard.implicitWidth + 24
  implicitHeight: popupCard.implicitHeight + 24
  grabFocus: true
  color: "transparent"
  mask: Region {
    item: popupCard
  }

  StyledRectangularShadow {
    target: popupCard
    elevation: Styles.elevation.e1
  }

  StyledRect {
    id: popupCard

    anchors.centerIn: parent
    implicitWidth: Math.max(root.minCardWidth, cardCol.implicitWidth + 16)
    implicitHeight: cardCol.implicitHeight + 16
    radius: 8
    color: Theme.options.base
    border.width: 1
    border.color: Theme.options.surface0
    focus: root.closeOnEscape
    Keys.onEscapePressed: root.isOpen = false

    ColumnLayout {
      id: cardCol

      x: 8
      y: 8
      spacing: root.cardSpacing
    }
  }
}
