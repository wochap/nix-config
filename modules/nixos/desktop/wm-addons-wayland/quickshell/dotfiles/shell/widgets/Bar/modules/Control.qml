import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config
import qs.widgets.Bar.modules

WrapperRectangle {
  id: root

  property bool isHovered: false

  leftMargin: 2
  rightMargin: root.leftMargin + 1
  color: root.isHovered ? Theme.options.surface1 : SControlCenter.isOpen ? Theme.options.surface0 : "transparent"
  radius: ConfigBar.modulesRadius

  child: Item {
    implicitWidth: controlContent.implicitWidth
    implicitHeight: controlContent.implicitHeight

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      onClicked: event => {
        switch (event.button) {
        case Qt.LeftButton:
          SControlCenter.toggle();
          break;
        }
        event.accepted = true;
      }
    }

    HoverHandler {
      onHoveredChanged: {
        root.isHovered = hovered;
      }
    }

    RowLayout {
      id: controlContent

      anchors.fill: parent
      spacing: 0

      MaterialIcon {
        Layout.fillHeight: true
        icon: SBluetooth.icon
        size: Styles.font.pixelSize.larger
        weight: Font.Light
        color: SBluetooth.iconColor
      }

      SystemIcon {
        Layout.fillHeight: true
        icon: SNetwork.icon
        size: Styles.font.pixelSize.hugeass
        enableColoriser: true
        color: SNetwork.iconColor
      }

      SystemIcon {
        Layout.fillHeight: true
        icon: SPipewire.outputIcon
        size: Styles.font.pixelSize.hugeass
        enableColoriser: true
        color: SPipewire.outputIconColor
      }

      SystemIcon {
        Layout.fillHeight: true
        icon: SPipewire.inputIcon
        size: Styles.font.pixelSize.hugeass
        enableColoriser: true
        color: SPipewire.inputIconColor
      }

      MaterialIcon {
        Layout.fillHeight: true
        Layout.leftMargin: -1
        Layout.rightMargin: 3
        icon: SPowerProfiles.icon
        color: SPowerProfiles.iconColor
        size: Styles.font.pixelSize.huge
        weight: Font.Light
      }

      SystemIcon {
        Layout.fillHeight: true
        icon: SUpower.batteryIcon
        size: Styles.font.pixelSize.hugeass
      }
    }
  }
}
