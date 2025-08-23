import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.widgets.Bar.config
import qs.widgets.Bar.modules

RowLayout {
  id: root

  anchors {
    right: parent.right
    rightMargin: ConfigBar.barPaddingX
    top: parent.top
    topMargin: ConfigBar.barPaddingY
    bottom: parent.bottom
    bottomMargin: ConfigBar.barPaddingY
  }

  spacing: ConfigBar.modulesSpacing

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
