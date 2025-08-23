import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

WrapperMouseArea {
  id: root

  required property SystemTrayItem modelData
  required property SystemTrayItem item
  property var window: root.QsWindow.window
  property int size: Styles.font.pixelSize.large

  child: trayIcon
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  leftMargin: size * 0.2
  rightMargin: size * 0.2
  onClicked: event => {
    switch (event.button) {
    case Qt.LeftButton:
      item.activate();
      break;
    case Qt.RightButton:
      if (item.hasMenu)
        menu.open();
      break;
    }
    event.accepted = true;
  }

  IconImage {
    id: trayIcon

    source: root.item.icon
    implicitWidth: root.size
    implicitHeight: root.size
    width: root.size
    height: root.size
  }

  QsMenuAnchor {
    id: menu

    menu: root.item.menu
    anchor.window: window
    anchor.rect.x: root.x + (window?.width)
    anchor.rect.y: root.y
    anchor.rect.height: root.height
    anchor.rect.width: root.width
    anchor.edges: ConfigBar.isBarAtBottom ? (Edges.Top | Edges.Left) : (Edges.Bottom | Edges.Right)
  }
}
