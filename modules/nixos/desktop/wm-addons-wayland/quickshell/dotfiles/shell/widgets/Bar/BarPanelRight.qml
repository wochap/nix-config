import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.widgets.Bar.config
import qs.widgets.Bar.modules
import qs.widgets.Bar.modules.SysTray

RowLayout {
  id: root

  spacing: ConfigBar.modulesSpacing

  Capslock {
    Layout.fillHeight: true
  }

  SysTray {
    Layout.fillHeight: true
  }

  Module {
    paddingX: 0
    bgColor: "transparent"
    iconSystem: "user-idle"
  }

  Control {
    Layout.fillHeight: true
  }

  Module {
    id: clock

    SystemClock {
      id: clockService
      precision: SystemClock.Minutes
    }

    Layout.fillHeight: true
    bgColor: "transparent"
    label: Qt.formatDateTime(clockService.date, "ddd dd MMM HH:mm")
  }
}
