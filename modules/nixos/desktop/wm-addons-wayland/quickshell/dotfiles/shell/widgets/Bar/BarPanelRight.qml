import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config
import qs.widgets.Bar.modules
import qs.widgets.Bar.modules.SysTray

RowLayout {
  id: root

  spacing: ConfigBar.modulesSpacing

  Capslock {
    Layout.fillHeight: true
  }

  Idle {
    Layout.fillHeight: true
  }

  SysTray {
    Layout.fillHeight: true
  }

  Control {
    Layout.fillHeight: true
  }

  StyledText {
    id: clock

    Layout.fillHeight: true
    text: Qt.formatDateTime(clockService.date, "ddd dd MMM HH:mm")

    SystemClock {
      id: clockService
      precision: SystemClock.Minutes
    }
  }
}
