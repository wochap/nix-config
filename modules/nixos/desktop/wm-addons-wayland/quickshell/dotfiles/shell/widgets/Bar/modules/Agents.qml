pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.Bar.config

RowLayout {
  id: root

  property int runningCount: SAgents.runningCount
  property int blockedCount: SAgents.blockedCount
  property bool isVisible: runningCount > 0 || blockedCount > 0

  visible: isVisible
  spacing: ConfigBar.modulesSpacing

  Loader {
    active: root.runningCount > 0
    visible: active
    sourceComponent: Component {
      Module {
        materialIcon: "smart_toy"
        iconSize: Styles.font.pixelSize.huge
        label: root.runningCount > 1 ? root.runningCount.toString() : ""
        paddingX: 0
        bgColor: "transparent"
        fgColor: Theme.options.green
      }
    }
  }

  Loader {
    active: root.blockedCount > 0
    visible: active
    sourceComponent: Component {
      Module {
        materialIcon: "pending_actions"
        iconSize: Styles.font.pixelSize.huge
        label: root.blockedCount > 1 ? root.blockedCount.toString() : ""
        paddingX: 0
        bgColor: "transparent"
        fgColor: Theme.options.yellow
      }
    }
  }
}
