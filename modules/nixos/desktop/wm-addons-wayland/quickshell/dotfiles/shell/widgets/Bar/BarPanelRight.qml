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

  SysTray {
    Layout.fillHeight: true
  }

  RowLayout {
    Layout.fillHeight: true

    Layout.leftMargin: -ConfigBar.modulesSpacing / 3
    Layout.rightMargin: -ConfigBar.modulesSpacing / 3
    spacing: 0
    visible: capslock.isLock || idle.isIdle

    Capslock {
      id: capslock

      Layout.fillHeight: true
    }

    Idle {
      id: idle

      Layout.fillHeight: true
    }
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
