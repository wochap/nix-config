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
    Layout.preferredWidth: item ? item.implicitWidth : 0
  }

  Idle {
    Layout.fillHeight: true
    Layout.preferredWidth: item ? item.implicitWidth : 0
  }

  SysTray {
    Layout.fillHeight: true
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
