import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

StatusModule {
  id: root

  property bool isIdleInhibit: false

  isVisible: root.isIdleInhibit
  sourceComponent: Component {
    MaterialIcon {
      icon: "coffee"
      size: root.iconSize
      weight: Font.Normal
      fill: 1
      color: Theme.options.peach
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
