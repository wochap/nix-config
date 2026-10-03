import QtQuick
import qs.config

// 24px filled pill (actions, sidebar header)
NotificationButton {
  id: root

  // first action of a card is drawn as an outline
  property bool isPrimary: false
  property color accent: Theme.options.primary

  size: 24
  fg: root.isPrimary ? root.accent : Theme.options.text
  bg: root.isPrimary ? "transparent" : Theme.options.surface0
  hoverBg: root.isPrimary ? Theme.addAlpha(root.accent, Styles.tint.hover) : Theme.options.surface1
  borderColor: root.isPrimary ? Theme.addAlpha(root.accent, 0.6) : "transparent"
}
