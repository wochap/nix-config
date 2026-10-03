pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  property real calendarWidth: 320
  property real calendarPadding: 12
  property real calendarSpacing: 12
  // gap between the bar and the popover, and from the right edge
  property real calendarMargin: 6
  property real dayCellHeight: 34
  property real weekColumnWidth: 24
  property real cardPadding: 10
  property real iconButtonSize: 28
  // 0 = Sunday, 1 = Monday (matches khal `firstweekday = 0`)
  property int firstDayOfWeek: 1
}
