import QtQuick
import qs.config

// 22px round ghost icon button (expand / close)
NotificationButton {
  id: root

  size: ConfigNotifications.notificationButtonSize
  fg: Theme.options.overlay1
  hoverFg: Theme.options.text
  bg: "transparent"
  hoverBg: Theme.options.surface1
}
