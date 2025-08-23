import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

RowLayout {
  id: gridLayout

  spacing: ConfigBar.modulesSpacing * 2

  Repeater {
    model: SystemTray.items

    SysTrayItem {
      item: modelData
    }
  }
}
