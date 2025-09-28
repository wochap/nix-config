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

  leftMargin: 2
  rightMargin: root.leftMargin + 1
  color: "transparent"
  radius: ConfigBar.modulesRadius

  RowLayout {
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
      icon: SPowerProfile.icon
      color: SPowerProfile.iconColor
      size: Styles.font.pixelSize.huge
      weight: Font.Light
    }

    SystemIcon {
      property string batteryIcon: SUpower.getIcon()

      Layout.fillHeight: true
      icon: batteryIcon
      size: Styles.font.pixelSize.hugeass
    }
  }
}
