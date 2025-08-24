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
      property string bluetoothIcon: Bluetooth.getIcon()

      Layout.fillHeight: true

      icon: bluetoothIcon
      size: Styles.font.pixelSize.larger
      weight: Font.Light
    }

    SystemIcon {
      property string networkIcon: Network.getIcon()

      Layout.fillHeight: true

      icon: networkIcon
      size: Styles.font.pixelSize.hugeass
      enableColoriser: true
      color: Theme.options.text
    }

    SystemIcon {
      property string volumeIcon: Audio.getOutputIcon()

      Layout.fillHeight: true

      icon: volumeIcon
      size: Styles.font.pixelSize.hugeass
      enableColoriser: true
      color: Theme.options.text
    }

    SystemIcon {
      property string volumeIcon: Audio.getInputIcon()

      Layout.fillHeight: true

      icon: volumeIcon
      size: Styles.font.pixelSize.hugeass
      enableColoriser: true
      color: Theme.options.text
    }

    SystemIcon {
      property string batteryIcon: Battery.getIcon()

      Layout.fillHeight: true

      icon: batteryIcon
      size: Styles.font.pixelSize.hugeass
    }
  }
}
