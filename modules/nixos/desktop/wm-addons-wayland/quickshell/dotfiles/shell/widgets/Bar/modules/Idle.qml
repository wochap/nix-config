import Quickshell.Io
import QtQuick

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property bool isIdle: false

  active: isIdle
  visible: isIdle
  sourceComponent: Component {
    MaterialIcon {
      icon: "emoji_food_beverage"
      size: Styles.font.pixelSize.hugeass
      color: Theme.options.red
    }
  }

  Process {
    command: ["shell-idle", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isIdle = JSON.parse(data);
        root.isIdle = isIdle;
      }
    }
  }
}
