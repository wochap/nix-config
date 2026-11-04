pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property alias options: jsonAdapter
  property bool ready: true
  signal changed

  FileView {
    id: fileView

    path: `${Qt.resolvedUrl(Paths.shellConfig)}/settings.json`
    watchChanges: true
    onLoaded: {
      fileView.reload();
      root.ready = true;
      root.changed();
    }
    onFileChanged: {
      fileView.reload();
      root.changed();
    }
    onLoadFailed: error => {
      root.ready = true;
    }

    JsonAdapter {
      id: jsonAdapter

      property bool renderBar: true
      property bool renderVBar: false
      property bool isBlurEnabled: false
    }
  }
}
