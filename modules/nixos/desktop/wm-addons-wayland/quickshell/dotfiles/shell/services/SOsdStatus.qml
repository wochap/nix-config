pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
  id: root

  property var currentOsd: null

  function requestShow(osdInstance) {
    if (currentOsd && currentOsd !== osdInstance) {
      currentOsd.forceClose();
    }
    if (currentOsd !== osdInstance) {
      currentOsd = osdInstance;
    }
  }
}
