pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  property real controlCenterWidth: 320
  property real controlCenterPadding: 8
  property real controlCenterSpacing: 8
  property bool isBlurEnabled: Global.isBlurEnabled
}

