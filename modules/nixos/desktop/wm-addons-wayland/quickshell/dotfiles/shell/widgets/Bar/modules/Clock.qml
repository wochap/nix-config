import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets.common

// Clock, opens the calendar popover
BarChipButton {
  id: root

  implicitWidth: clockText.implicitWidth + 20
  Layout.fillHeight: true
  radius: height / 2
  active: SCalendar.isOpen
  accessibleName: `Calendar, ${Qt.formatDateTime(clockService.date, "dddd d MMMM HH:mm")}`
  hintLabel: "Calendar"
  onClicked: SCalendar.toggle()

  StyledText {
    id: clockText

    anchors.centerIn: parent
    text: Qt.formatDateTime(clockService.date, "ddd dd MMM HH:mm")
    font.pixelSize: 12
    font.weight: 500
    color: Theme.options.text
  }

  SystemClock {
    id: clockService

    precision: SystemClock.Minutes
  }
}
