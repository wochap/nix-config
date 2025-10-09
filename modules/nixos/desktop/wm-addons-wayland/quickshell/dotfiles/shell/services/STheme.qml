pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool isDarkModeActive: false

  function disableDarkMode() {
    root.isDarkModeActive = false;
    Quickshell.execDetached(["bash", "-c", "shell-theme light"]);
  }

  function enableDarkMode() {
    root.isDarkModeActive = true;
    Quickshell.execDetached(["bash", "-c", "shell-theme dark"]);
  }

  function toggleDarkMode() {
    if (root.isDarkModeActive) {
      disableDarkMode();
    } else {
      enableDarkMode();
    }
  }

  function getState() {
    getStatus.running = true;
  }

  Process {
    id: getStatus

    running: true
    command: ["bash", "-c", "shell-theme --status"]
    stdout: StdioCollector {
      id: statusCollector

      onStreamFinished: {
        const output = statusCollector.text.trim();
        root.isDarkModeActive = output === "dark";
      }
    }
  }
}
