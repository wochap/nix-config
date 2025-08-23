import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config
import qs.widgets.Bar.modules

WrapperRectangle {
  id: root

  leftMargin: ConfigBar.modulesPaddingX
  rightMargin: ConfigBar.modulesPaddingX
  color: Theme.options.surface0
  radius: 4

  RowLayout {
    spacing: ConfigBar.modulesSpacing / 2

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
      property string volumeIcon: Audio.getIcon()

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
