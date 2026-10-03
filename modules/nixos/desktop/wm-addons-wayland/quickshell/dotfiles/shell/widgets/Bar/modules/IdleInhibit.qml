import Quickshell.Io
import QtQuick
import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property bool isIdleInhibit: false
  property bool isVisible: isIdleInhibit

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    SystemIcon {
      enableColoriser: true
      icon: "caffeine-cup-full"
      size: Styles.font.pixelSize.hugeass
      color: Theme.options.maroon
    }
  }

  Process {
    command: ["shell-idle-inhibit", "--listen"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const isIdleInhibit = JSON.parse(data);
        root.isIdleInhibit = isIdleInhibit;
      }
    }
  }
}
