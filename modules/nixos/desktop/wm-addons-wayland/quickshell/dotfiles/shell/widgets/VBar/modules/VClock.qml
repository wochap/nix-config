import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config

BarChipButton {
  id: root

  implicitWidth: 36
  implicitHeight: col.implicitHeight + 12
  radius: 18
  active: SCalendar.isOpen
  animateColor: false
  accessibleName: `Calendar, ${Qt.formatDateTime(clockService.date, "dddd d MMMM HH:mm")}`
  hintLabel: "Calendar"
  onClicked: SCalendar.toggle()

  ColumnLayout {
    id: col

    anchors.centerIn: parent
    spacing: 0

    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: Qt.formatDateTime(clockService.date, "HH")
      font.pixelSize: 15
      font.weight: 500
      color: Theme.options.text
    }

    StyledText {
      Layout.alignment: Qt.AlignHCenter
      text: Qt.formatDateTime(clockService.date, "mm")
      font.pixelSize: 15
      font.weight: 500
      color: Theme.options.text
    }

    StyledText {
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 2
      text: Qt.formatDateTime(clockService.date, "dd·MM")
      font.pixelSize: 10
      color: Theme.options.subtext0
    }
  }

  SystemClock {
    id: clockService

    precision: SystemClock.Minutes
  }
}
