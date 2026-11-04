import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.VBar.config
import qs.Woints

Rectangle {
  id: root

  property bool isHovered: false

  implicitWidth: 36
  implicitHeight: col.implicitHeight + 12
  radius: 18
  color: root.isHovered ? Theme.options.surface1 : SCalendar.isOpen ? Theme.options.surface0 : "transparent"
  border.width: SCalendar.isOpen ? 1 : 0
  border.color: Theme.options.primary

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

  HoverHandler {
    onHoveredChanged: root.isHovered = hovered
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton
    onClicked: SCalendar.toggle()
    Accessible.role: Accessible.Button
    Accessible.name: `Calendar, ${Qt.formatDateTime(clockService.date, "dddd d MMMM HH:mm")}`
    Accessible.checkable: true
    Accessible.checked: SCalendar.isOpen
    Accessible.onPressAction: SCalendar.toggle()

    Hintable {
      label: "Calendar"
      onActivated: SCalendar.toggle()
    }
  }
}
