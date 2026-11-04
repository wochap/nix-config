import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.config
import qs.widgets.common
import qs.widgets.VBar.config

Item {
  id: root

  property alias isOpen: popup.isOpen
  readonly property int trayCount: SystemTray.items.values.length
  readonly property bool hasItems: root.trayCount > 0

  visible: hasItems
  implicitWidth: ConfigVBar.trayButtonWidth
  implicitHeight: ConfigVBar.trayButtonHeight

  onTrayCountChanged: {
    if (trayCount === 0) isOpen = false;
  }

  BarChipButton {
    id: button

    anchors.fill: parent
    radius: ConfigVBar.trayButtonRadius
    active: root.isOpen
    hoverColor: Theme.options.surface0
    accessibleName: `System tray, ${root.trayCount} items`
    hintLabel: "System tray"
    onClicked: root.isOpen = !root.isOpen

    MaterialIcon {
      anchors.centerIn: parent
      icon: "more_horiz"
      size: ConfigVBar.trayButtonIconSize
      weight: Font.Normal
      color: Theme.options.subtext0
    }
  }

  SysTrayPopup {
    id: popup

    anchor.item: button
    anchor.edges: Edges.Right | Edges.Top
    anchor.gravity: Edges.Right | Edges.Bottom
    anchor.margins.right: 2
    anchor.margins.top: -8
    itemIconSize: ConfigVBar.trayItemIconSize
    itemSize: ConfigVBar.trayItemSize
    itemRadius: ConfigVBar.trayItemRadius
    itemDefaultColor: Theme.options.surface0
    itemHoverColor: Theme.options.surface1
    itemPressedColor: Theme.options.surface2
    itemMenuEdges: Edges.Bottom | Edges.Left
  }
}
