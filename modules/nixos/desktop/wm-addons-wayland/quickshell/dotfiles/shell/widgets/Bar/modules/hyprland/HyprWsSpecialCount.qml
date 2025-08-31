import Quickshell.Io
import QtQuick
import qs.config
import qs.widgets.Bar.config
import qs.widgets.Bar.modules

Loader {
  id: root

  property string fgColor: Theme.options.lavender
  property string namespace: ""
  property int count: 0

  active: root.count > 0
  visible: root.count > 0
  sourceComponent: Component {
    Module {
      iconSize: Styles.font.pixelSize.normal
      fgColor: root.fgColor
      icon: " "
      label: root.count
    }
  }

  Process {
    command: ["shell-hypr-ws-special-count", root.namespace]
    running: true
    stdout: SplitParser {
      onRead: data => {
        const count = JSON.parse(data);
        root.count = count;
      }
    }
  }
}
