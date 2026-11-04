import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

StatusModule {
  id: root

  property int runningCount: SAgents.runningCount
  property int blockedCount: SAgents.blockedCount
  readonly property int total: root.runningCount + root.blockedCount

  isVisible: root.total > 0
  sourceComponent: Component {
    StatusBadge {
      vertical: root.vertical
      icon: root.blockedCount > 0 ? "pending_actions" : "smart_toy"
      iconColor: root.blockedCount > 0 ? Theme.options.yellow : Theme.options.mauve
      iconSize: root.iconSize
      text: root.total.toString()
      textVisible: root.total > 1
      fontSize: root.fontSize
    }
  }
}
