import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import qs.config
import qs.widgets.common
import qs.widgets.VBar.config
import qs.widgets.Bar.modules.SysTray
import qs.Woints

Item {
  id: root

  property bool isOpen: false
  readonly property int trayCount: SystemTray.items.values.length
  readonly property bool hasItems: root.trayCount > 0

  visible: hasItems
  implicitWidth: ConfigVBar.trayButtonWidth
  implicitHeight: ConfigVBar.trayButtonHeight

  onTrayCountChanged: {
    if (trayCount === 0) isOpen = false;
  }

  Rectangle {
    id: button

    anchors.fill: parent
    radius: ConfigVBar.trayButtonRadius
    color: root.isOpen ? Theme.options.surface0 : hoverHandler.hovered ? Theme.options.surface0 : "transparent"
    border.width: root.isOpen ? 1 : 0
    border.color: Theme.options.primary

    Behavior on color {
      animation: Styles.animations.colorAnimation.createObject(this)
    }

    MaterialIcon {
      anchors.centerIn: parent
      icon: "more_horiz"
      size: ConfigVBar.trayButtonIconSize
      weight: Font.Normal
      color: root.isOpen ? Theme.options.subtext0 : Theme.options.subtext0
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
    anchor.edges: Edges.Right | Edges.Top
    anchor.gravity: Edges.Right | Edges.Bottom
    anchor.margins.right: 2
    anchor.margins.top: -8
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
              size: ConfigVBar.trayItemIconSize
              chipWidth: ConfigVBar.trayItemSize
              chipHeight: ConfigVBar.trayItemSize
              chipRadius: ConfigVBar.trayItemRadius
              defaultColor: Theme.options.surface0
              hoverColor: Theme.options.surface1
              pressedColor: Theme.options.surface2
              menuEdges: Edges.Bottom | Edges.Left
            }
          }
        }
      }
    }
  }
}
