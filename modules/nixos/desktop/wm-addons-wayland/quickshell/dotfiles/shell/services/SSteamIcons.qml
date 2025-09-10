pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property var iconsByAppId: ({})

  function getIconPath(appId) {
    if (!root.iconsByAppId[appId]) {
      return null;
    }
    return `file://${root.iconsByAppId[appId]}`;
  }

  Process {
    command: ["shell-steam-icons"]
    running: true
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        if (statusCollector.text) {
          root.iconsByAppId = JSON.parse(statusCollector.text);
        }
      }
    }
  }
}
