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
    spacing: ConfigBar.modulesSpacing

    Module {
      Layout.fillHeight: true

      paddingX: 0
      bgColor: "transparent"
      iconSystem: "network-wireless-signal-good"
    }

    Module {
      property string volumeIcon: Audio.getIcon()

      Layout.fillHeight: true

      paddingX: 0
      bgColor: "transparent"
      iconSystem: volumeIcon
    }

    Module {
      property string batteryIcon: Battery.getIcon()

      Layout.fillHeight: true

      paddingX: 0
      bgColor: "transparent"
      iconSystem: batteryIcon
    }
  }
}
