import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import qs.config
import qs.widgets.common
import qs.widgets.Bar.config

Loader {
  id: root

  property string value: ""
  property bool isVisible: value.length > 0

  active: isVisible
  visible: isVisible
  sourceComponent: Component {
    Module {
      materialIcon: "punch_clock"
      iconSize: Styles.font.pixelSize.huge
      label: value
      paddingX: 0
      bgColor: "transparent"
      fgColor: Theme.options.green
    }
  }

  Process {
    id: process

    command: ["bash", "-c", `timew | grep 'Total' | awk '{split($2, a, ":"); print a[1] ":" a[2]}'`]
    running: true
    stdout: StdioCollector {
      id: stdioCollector

      onStreamFinished: data => {
        root.value = stdioCollector.text?.trim?.();
      }
    }
  }

  Timer {
    id: timer

    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      process.running = true;
    }
  }
}
