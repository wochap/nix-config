import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

MouseArea {
  id: root

  required property SystemTrayItem modelData
  required property SystemTrayItem item
  property int size: Styles.font.pixelSize.small

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  implicitWidth: size
  implicitHeight: size
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

    anchors.centerIn: parent
    source: root.item.icon
    implicitSize: root.size

    QsMenuAnchor {
      id: menu

      menu: root.item.menu
      anchor.item: trayIcon
      anchor.rect.x: 0
      anchor.rect.y: trayIcon.y + trayIcon.height + 4
      anchor.edges: ConfigBar.isBarAtBottom ? (Edges.Top | Edges.Left) : (Edges.Bottom | Edges.Left)
    }
  }
}
