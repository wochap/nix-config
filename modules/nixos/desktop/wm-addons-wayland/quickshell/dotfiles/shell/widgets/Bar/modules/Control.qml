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
  color: Theme.options.surface0
  radius: ConfigBar.modulesRadius

  RowLayout {
    spacing: 0

    MaterialIcon {

      Layout.fillHeight: true
      icon: Bluetooth.icon
      size: Styles.font.pixelSize.larger
      weight: Font.Light
      color: Bluetooth.iconColor
    }

    SystemIcon {
      Layout.fillHeight: true
      icon: Network.icon
      size: Styles.font.pixelSize.hugeass
      enableColoriser: true
      color: Network.iconColor
    }

    SystemIcon {

      Layout.fillHeight: true
      icon: Audio.outputIcon
      size: Styles.font.pixelSize.hugeass
      enableColoriser: true
      color: Audio.outputIconColor
    }

    SystemIcon {

      Layout.fillHeight: true
      icon: Audio.inputIcon
      size: Styles.font.pixelSize.hugeass
      enableColoriser: true
      color: Audio.inputIconColor
    }

    MaterialIcon {
      Layout.fillHeight: true
      Layout.leftMargin: -1
      Layout.rightMargin: 3
      icon: PowerProfile.icon
      color: PowerProfile.iconColor
      size: Styles.font.pixelSize.huge
      weight: Font.Light
    }

    SystemIcon {
      property string batteryIcon: Battery.getIcon()

      Layout.fillHeight: true
      icon: batteryIcon
      size: Styles.font.pixelSize.hugeass
    }
  }
}
