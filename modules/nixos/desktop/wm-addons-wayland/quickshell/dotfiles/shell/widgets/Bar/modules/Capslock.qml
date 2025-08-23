import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property bool isLock: false

  active: isLock
  visible: isLock
  sourceComponent: Component {
    MaterialIcon {
      icon: "keyboard_capslock_badge"
      size: Styles.font.pixelSize.huge
      color: Theme.options.peach
    }
  }

  Process {
    command: ["shell-capslock"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isLock = JSON.parse(data);
        root.isLock = isLock;
      }
    }
  }
}
