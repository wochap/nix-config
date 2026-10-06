import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Lock

// user@host, uptime and lock time, top-right of the focused output
RowLayout {
  id: root

  spacing: 10

  // uptime only moves while the lock is shown
  Timer {
    running: SLockSession.isLocked
    interval: 60000
    repeat: true
    onTriggered: SSystemInfo.refresh()
  }

  ColumnLayout {
    spacing: 0

    StyledText {
      Layout.alignment: Qt.AlignRight
      text: `${SSystemInfo.user}@${SSystemInfo.host}`
      font.pixelSize: Styles.font.pixelSize.small
      font.weight: Font.Medium
      lineHeight: 16
      lineHeightMode: Text.FixedHeight
    }

    StyledText {
      Layout.alignment: Qt.AlignRight
      text: `up ${SSystemInfo.uptime}`
      color: ConfigLock.subtext
      font.pixelSize: Styles.font.pixelSize.small
      lineHeight: 16
      lineHeightMode: Text.FixedHeight
    }

    RowLayout {
      Layout.alignment: Qt.AlignRight
      spacing: 4

      MaterialIcon {
        icon: "lock"
        size: 12
        fill: 1
        weight: Font.Normal
        color: ConfigLock.subtext
      }

      StyledText {
        text: `Locked ${Qt.formatTime(SLockSession.lockedAt, "HH:mm")}`
        color: ConfigLock.subtext
        font.pixelSize: Styles.font.pixelSize.small
        lineHeight: 16
        lineHeightMode: Text.FixedHeight
      }
    }
  }

  StyledRect {
    Layout.preferredWidth: 32
    Layout.preferredHeight: 32
    radius: width / 2
    color: Theme.options.surface0
    border.width: 1
    border.color: Theme.options.surface1

    StyledText {
      anchors.centerIn: parent
      text: SSystemInfo.user.charAt(0).toUpperCase()
      color: ConfigLock.ink
      font.weight: Font.Medium
    }
  }
}
