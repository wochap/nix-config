import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.Woints

MouseArea {
  id: root

  required property SystemTrayItem modelData
  required property SystemTrayItem item
  property int size: Styles.font.pixelSize.small

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  implicitWidth: size
  implicitHeight: size
  Accessible.role: Accessible.Button
  Accessible.name: root.item.tooltipTitle || root.item.title || root.item.id
  Accessible.onPressAction: root.item.activate()
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

  Hintable {
    target: root
    label: root.Accessible.name
    actions: ["click", "right"]
    onActivated: action => {
      if (action === "right") {
        if (root.item.hasMenu)
          menu.open();
      } else {
        root.item.activate();
      }
    }
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
