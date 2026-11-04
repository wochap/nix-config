pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common
import qs.widgets.Bar.config

RowLayout {
  id: root

  property int runningCount: SAgents.runningCount
  property int blockedCount: SAgents.blockedCount
  readonly property int total: root.runningCount + root.blockedCount
  property bool isVisible: root.total > 0

  visible: isVisible
  spacing: 4

  MaterialIcon {
    icon: root.blockedCount > 0 ? "pending_actions" : "smart_toy"
    size: ConfigBar.statusIconSize
    weight: Font.Normal
    color: root.blockedCount > 0 ? Theme.options.yellow : Theme.options.mauve
  }

  StyledText {
    visible: root.total > 1
    text: root.total.toString()
    font.pixelSize: ConfigBar.statusFontSize
    font.weight: 600
    color: Theme.options.subtext1
  }
}
