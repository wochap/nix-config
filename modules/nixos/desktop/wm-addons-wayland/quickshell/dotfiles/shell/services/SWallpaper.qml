pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// current awww wallpaper per output
Singleton {
  id: root

  readonly property string fallback: `${Quickshell.env("HOME")}/Pictures/backgrounds/lock.jpg`
  // output name -> image path
  property var paths: ({})

  function refresh() {
    queryProcess.running = true;
  }

  function pathFor(name) {
    return root.paths[name] ?? root.fallback;
  }

  Process {
    id: queryProcess

    running: true
    command: ["awww", "query"]
    stdout: StdioCollector {
      onStreamFinished: {
        const paths = {};
        // ": HDMI-A-1: 1920x1080, scale: 1, currently displaying: image: /path"
        for (const line of text.split("\n")) {
          const match = line.match(/^:?\s*([^:\s]+):.*image: (.+)$/);
          if (match) {
            paths[match[1]] = match[2].trim();
          }
        }
        root.paths = paths;
      }
    }
  }
}
