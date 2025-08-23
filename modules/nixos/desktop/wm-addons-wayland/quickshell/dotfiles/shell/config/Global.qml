pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
  id: root

  property bool isBlurEnabled: false
  property bool areAnimationsEnabled: false
}
