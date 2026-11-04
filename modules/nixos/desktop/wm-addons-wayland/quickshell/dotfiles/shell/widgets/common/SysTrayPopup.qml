import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common

// Popover with a 3-column grid of system tray items. Callers set `anchor.*`
// and the item sizing/colors for their bar.
PopupCard {
  id: root

  property int itemIconSize: 16
  property int itemSize: 28
  property int itemRadius: 14
  property color itemDefaultColor: "transparent"
  property color itemHoverColor: Theme.options.surface0
  property color itemPressedColor: Theme.options.surface1
  property int itemMenuEdges: Edges.Bottom | Edges.Left

  minCardWidth: 108
  cardSpacing: 6

  PopupCardHeader {
    text: `TRAY · ${SystemTray.items.values.length}`
    Layout.leftMargin: 2
  }

  Grid {
    columns: 3
    spacing: 4
    Layout.alignment: Qt.AlignLeft

    Repeater {
      model: SystemTray.items

      delegate: SysTrayItem {
        item: modelData
        size: root.itemIconSize
        chipWidth: root.itemSize
        chipHeight: root.itemSize
        chipRadius: root.itemRadius
        defaultColor: root.itemDefaultColor
        hoverColor: root.itemHoverColor
        pressedColor: root.itemPressedColor
        menuEdges: root.itemMenuEdges
      }
    }
  }
}
