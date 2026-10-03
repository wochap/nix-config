import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

StyledRect {
  id: root

  // "Today 18:00", "Fri 09:30" within a week, "Tue 6 · 14:00" or "Wed 14 · all day" after
  function formatWhen(event) {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const days = Math.round((new Date(event.start.getFullYear(), event.start.getMonth(), event.start.getDate()) - today) / 86400000);
    const time = event.allDay ? "all day" : Qt.formatTime(event.start, "HH:mm");
    if (days <= 0)
      return `Today ${event.allDay ? "· all day" : time}`;
    if (days === 1)
      return `Tomorrow ${event.allDay ? "· all day" : time}`;
    if (days < 7)
      return event.allDay ? `${Qt.formatDate(event.start, "ddd")} · all day` : `${Qt.formatDate(event.start, "ddd")} ${time}`;
    return `${Qt.formatDate(event.start, "ddd d")} · ${time}`;
  }

  implicitHeight: content.implicitHeight + ConfigCalendar.cardPadding * 2
  radius: Styles.radius.windowRounding
  color: Theme.options.mantle
  border {
    width: 1
    color: Theme.options.surface0
  }

  ColumnLayout {
    id: content

    anchors {
      fill: parent
      margins: ConfigCalendar.cardPadding
    }
    spacing: 6

    StyledText {
      text: "UPCOMING · khal"
      font.pixelSize: Styles.font.pixelSize.smaller
      font.letterSpacing: 1
      color: Theme.options.overlay1
    }

    Repeater {
      model: SKhal.upcoming

      RowLayout {
        required property var modelData

        Layout.fillWidth: true
        Layout.preferredHeight: 22
        spacing: 8

        Rectangle {
          implicitWidth: 3
          implicitHeight: 14
          radius: 2
          color: modelData.color
        }

        StyledText {
          Layout.preferredWidth: 84
          text: root.formatWhen(modelData)
          elide: Text.ElideRight
          font.pixelSize: Styles.font.pixelSize.smaller
          color: Theme.options.subtext0
        }

        StyledText {
          Layout.fillWidth: true
          text: modelData.title
          elide: Text.ElideRight
          font.pixelSize: Styles.font.pixelSize.small
        }
      }
    }

    StyledText {
      Layout.preferredHeight: 22
      visible: SKhal.upcoming.length === 0
      text: SKhal.available ? `Nothing in the next ${SKhal.upcomingDays} days` : "khal unavailable"
      font.pixelSize: Styles.font.pixelSize.small
      color: Theme.options.overlay1
    }
  }
}
