pragma Singleton

import Quickshell
import Qt.labs.platform

Singleton {
  id: root

  readonly property url config: `${StandardPaths.standardLocations(StandardPaths.GenericConfigLocation)[0]}`
  property string shellConfig: `${config}/quickshell`

  function stringify(path: url): string {
    let str = path.toString();
    if (str.startsWith("root:/"))
      str = `file://${Quickshell.shellDir}/${str.slice(6)}`;
    else if (str.startsWith("/"))
      str = `file://${str}`;
    return new URL(str).pathname;
  }

  function strip(path: url): string {
    return stringify(path).replace("file://", "");
  }
}
