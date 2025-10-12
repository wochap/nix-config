pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
  id: root

  property var list: []
  property var iconByProfile: ({
      performance: "rocket",
      balanced: "energy_savings_leaf",
      ["power-saver"]: "nest_eco_leaf"
    })
  property string active: ""
  property string icon: ""
  property string iconColor: ""

  Connections {
    target: Theme

    function onChanged(event) {
      listenProcess.running = false;
      listenProcess.running = true;
    }
  }

  function set(profile) {
    Quickshell.execDetached(["bash", "-c", `powerprofilesctl set ${profile}`]);
  }

  Process {
    id: listenProcess

    running: true
    command: ["bash", "-c", "shell-powerprofiles --listen"]
    stdout: SplitParser {
      onRead: data => {
        const profile = data;
        root.active = profile;
        if (profile === "performance") {
          root.icon = root.iconByProfile[profile];
          root.iconColor = Theme.options.text;
        } else if (profile === "balanced") {
          root.icon = root.iconByProfile[profile];
          root.iconColor = Theme.options.yellow;
        } else {
          root.icon = root.iconByProfile[profile];
          root.iconColor = Theme.options.green;
        }
      }
    }
  }

  Process {
    running: true
    command: ["bash", "-c", "shell-powerprofiles --list"]
    stdout: StdioCollector {
      id: getListCollector

      onStreamFinished: {
        const output = getListCollector.text.trim();
        root.list = (JSON.parse(output)).map(profile => {
          return {
            profile,
            icon: root.iconByProfile[profile]
          };
        });
      }
    }
  }
}
