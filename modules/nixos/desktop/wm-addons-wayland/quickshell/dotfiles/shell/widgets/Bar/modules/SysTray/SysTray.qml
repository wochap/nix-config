import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

Item {
  id: root

  property alias isOpen: popup.isOpen
  readonly property int trayCount: SystemTray.items.values.length
  readonly property bool hasItems: root.trayCount > 0

  visible: hasItems
  implicitWidth: ConfigBar.trayButtonWidth
  Layout.fillHeight: true

  onTrayCountChanged: {
    if (trayCount === 0) isOpen = false;
  }

  BarChipButton {
    id: button

    anchors.fill: parent
    radius: height / 2
    active: root.isOpen
    hoverColor: Theme.options.surface0
    accessibleName: `System tray, ${root.trayCount} items`
    hintLabel: "System tray"
    onClicked: root.isOpen = !root.isOpen

    MaterialIcon {
      anchors.centerIn: parent
      icon: "more_horiz"
      size: ConfigBar.trayButtonIconSize
      weight: Font.Normal
      color: Theme.options.subtext0
    }
  }

  SysTrayPopup {
    id: popup

    anchor.item: button
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.right: -12
    anchor.margins.top: Math.round(ConfigBar.barHeight - 6 - (ConfigBar.barPaddingY + button.height))
    anchor.margins.bottom: 0
    itemIconSize: ConfigBar.trayItemIconSize
    itemSize: ConfigBar.trayItemSize
    itemRadius: ConfigBar.trayItemRadius
  }
}
