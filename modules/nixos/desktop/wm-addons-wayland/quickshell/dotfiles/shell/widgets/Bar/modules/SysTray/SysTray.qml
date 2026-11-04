import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.widgets.Bar.modules.SysTray
import qs.Woints

Item {
  id: root

  property bool isOpen: false
  readonly property int trayCount: SystemTray.items.values.length
  readonly property bool hasItems: root.trayCount > 0

  visible: hasItems
  implicitWidth: ConfigBar.trayButtonWidth
  Layout.fillHeight: true

  onTrayCountChanged: {
    if (trayCount === 0) isOpen = false;
  }

  Rectangle {
    id: button

    anchors.fill: parent
    radius: height / 2
    color: root.isOpen ? Theme.options.surface0 : hoverHandler.hovered ? Theme.options.surface0 : "transparent"
    border.width: root.isOpen ? 1 : 0
    border.color: Theme.options.primary

    Behavior on color {
      animation: Styles.animations.colorAnimation.createObject(this)
    }

    MaterialIcon {
      anchors.centerIn: parent
      icon: "more_horiz"
      size: ConfigBar.trayButtonIconSize
      weight: Font.Normal
      color: Theme.options.subtext0
    }

    HoverHandler {
      id: hoverHandler
    }

    MouseArea {
      id: mouseArea

      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.isOpen = !root.isOpen
      Accessible.role: Accessible.Button
      Accessible.name: `System tray, ${root.trayCount} items`
      Accessible.checkable: true
      Accessible.checked: root.isOpen
      Accessible.onPressAction: root.isOpen = !root.isOpen

      Hintable {
        label: "System tray"
        onActivated: root.isOpen = !root.isOpen
      }
    }
  }

  PopupWindow {
    id: popup

    visible: root.isOpen
    anchor.item: button
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.right: -12
    anchor.margins.top: Math.round(ConfigBar.barHeight - 6 - (ConfigBar.barPaddingY + button.height))
    anchor.margins.bottom: 0
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
      if (!visible) root.isOpen = false;
    }

    implicitWidth: popupCard.implicitWidth + 24
    implicitHeight: popupCard.implicitHeight + 24
    mask: Region {}

    StyledRectangularShadow {
      target: popupCard
      elevation: Styles.elevation.e1
    }

    StyledRect {
      id: popupCard

      anchors.centerIn: parent
      implicitWidth: Math.max(108, cardCol.implicitWidth + 16)
      implicitHeight: cardCol.implicitHeight + 16
      radius: 8
      color: Theme.options.base
      border.width: 1
      border.color: Theme.options.surface0

      ColumnLayout {
        id: cardCol

        x: 8
        y: 8
        spacing: 6

        StyledText {
          text: `TRAY · ${root.trayCount}`
          font.pixelSize: 10
          font.weight: 600
          font.letterSpacing: 0.6
          color: Theme.options.subtext0
          Layout.leftMargin: 2
        }

        Grid {
          id: trayGrid

          columns: 3
          spacing: 4
          Layout.alignment: Qt.AlignLeft

          Repeater {
            model: SystemTray.items

            delegate: SysTrayItem {
              item: modelData
              size: ConfigBar.trayItemIconSize
              chipWidth: ConfigBar.trayItemSize
              chipHeight: ConfigBar.trayItemSize
              chipRadius: ConfigBar.trayItemRadius
            }
          }
        }
      }
    }
  }
}
