import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

ColumnLayout {
  id: root

  required property date today
  // first day of the month being shown
  property date viewMonth: new Date(root.today.getFullYear(), root.today.getMonth(), 1)
  readonly property int leadingDays: (root.viewMonth.getDay() - ConfigCalendar.firstDayOfWeek + 7) % 7
  readonly property date gridStart: SKhal.addDays(root.viewMonth, -root.leadingDays)
  readonly property int daysInMonth: new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth() + 1, 0).getDate()
  readonly property int weekCount: Math.ceil((root.leadingDays + root.daysInMonth) / 7)
  readonly property bool isCurrentMonth: root.viewMonth.getFullYear() === root.today.getFullYear() && root.viewMonth.getMonth() === root.today.getMonth()

  function isoWeek(date) {
    // Thursday of the date's ISO week decides the year
    const d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7);
    const week1 = new Date(d.getFullYear(), 0, 4);
    return 1 + Math.round(((d - week1) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7);
  }

  function shiftMonth(delta) {
    root.viewMonth = new Date(root.viewMonth.getFullYear(), root.viewMonth.getMonth() + delta, 1);
  }

  function goToToday() {
    root.viewMonth = new Date(root.today.getFullYear(), root.today.getMonth(), 1);
  }

  function loadEvents() {
    SKhal.loadRange(root.gridStart, SKhal.addDays(root.gridStart, root.weekCount * 7 - 1));
  }

  spacing: ConfigCalendar.calendarSpacing
  onViewMonthChanged: root.loadEvents()
  Component.onCompleted: root.loadEvents()

  // Month header
  RowLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: ConfigCalendar.iconButtonSize
    spacing: 4

    StyledText {
      Layout.fillWidth: true
      Layout.leftMargin: 2
      text: Qt.formatDate(root.viewMonth, "MMMM yyyy")
      font.weight: Font.Medium
    }

    CalendarIconButton {
      icon: "chevron_left"
      onClicked: root.shiftMonth(-1)
    }

    CalendarIconButton {
      label: "Today"
      opacity: root.isCurrentMonth ? 0.45 : 1
      onClicked: root.goToToday()
    }

    CalendarIconButton {
      icon: "chevron_right"
      onClicked: root.shiftMonth(1)
    }
  }

  GridLayout {
    id: grid

    Layout.fillWidth: true
    columns: 8
    columnSpacing: 2
    rowSpacing: 2

    // Day-of-week header
    Item {
      Layout.preferredWidth: ConfigCalendar.weekColumnWidth
      Layout.preferredHeight: 20
    }

    Repeater {
      model: 7

      StyledText {
        required property int index

        // equal share of the remaining width
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 20
        horizontalAlignment: Text.AlignHCenter
        text: Qt.locale().dayName((index + ConfigCalendar.firstDayOfWeek) % 7, Locale.ShortFormat).slice(0, 2)
        font.pixelSize: Styles.font.pixelSize.smaller
        color: Theme.options.overlay0
      }
    }

    Repeater {
      model: root.weekCount * 8

      Loader {
        id: cell

        required property int index
        readonly property int week: Math.floor(index / 8)
        readonly property int column: index % 8
        readonly property date day: SKhal.addDays(root.gridStart, cell.week * 7 + cell.column - 1)

        Layout.fillWidth: cell.column !== 0
        Layout.preferredWidth: cell.column === 0 ? ConfigCalendar.weekColumnWidth : 1
        Layout.preferredHeight: ConfigCalendar.dayCellHeight
        sourceComponent: cell.column === 0 ? weekNumber : dayCell

        Component {
          id: weekNumber

          StyledText {
            horizontalAlignment: Text.AlignHCenter
            text: root.isoWeek(SKhal.addDays(cell.day, 1))
            font.pixelSize: Styles.font.pixelSize.smaller
            color: Theme.options.surface2
          }
        }

        Component {
          id: dayCell

          StyledRect {
            readonly property bool isToday: SKhal.dayKey(cell.day) === SKhal.dayKey(root.today)
            readonly property bool inMonth: cell.day.getMonth() === root.viewMonth.getMonth()
            readonly property bool isWeekend: cell.day.getDay() === 0 || cell.day.getDay() === 6
            readonly property var eventColors: SKhal.eventsByDay[SKhal.dayKey(cell.day)] ?? []

            radius: height / 2
            color: isToday ? Theme.options.mauve : dayMouseArea.containsMouse ? Theme.options.surface0 : "transparent"

            Column {
              anchors.centerIn: parent
              spacing: 2

              StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cell.day.getDate()
                font.pixelSize: Styles.font.pixelSize.small
                font.weight: isToday ? Font.Bold : Font.Normal
                lineHeight: 14
                lineHeightMode: Text.FixedHeight
                color: isToday ? Theme.options.crust : !inMonth ? Theme.options.surface1 : isWeekend ? Theme.options.subtext0 : Theme.options.text
              }

              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 3
                height: 3
                radius: 1.5
                color: inMonth && eventColors.length > 0 ? (isToday ? Theme.options.crust : eventColors[0]) : "transparent"
              }
            }

            MouseArea {
              id: dayMouseArea

              anchors.fill: parent
              hoverEnabled: true
            }
          }
        }
      }
    }

    // scroll to change month
    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: event => root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
    }
  }
}
