import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.config
import qs.widgets.common
import qs.Woints

MouseArea {
  id: root

  required property SystemTrayItem modelData
  required property SystemTrayItem item
  property int size: 16
  property int chipWidth: -1
  property int chipHeight: -1
  property int chipRadius: -1
  property color defaultColor: "transparent"
  property color hoverColor: Theme.options.surface0
  property color pressedColor: Theme.options.surface1
  property int menuEdges: Edges.Bottom | Edges.Left
  property int menuOffsetY: 4

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor
  implicitWidth: chipWidth > 0 ? chipWidth : 26
  implicitHeight: chipHeight > 0 ? chipHeight : 24
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

  Rectangle {
    anchors.fill: parent
    radius: root.chipRadius >= 0 ? root.chipRadius : height / 2
    color: root.pressed ? root.pressedColor : root.containsMouse ? root.hoverColor : root.defaultColor

    Behavior on color {
      animation: Styles.animations.colorAnimation.createObject(this)
    }
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
      anchor.rect.y: trayIcon.y + trayIcon.height + root.menuOffsetY
      anchor.edges: root.menuEdges
    }
  }
}
