pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
  id: root

  property real barHeight: 40
  property real barPaddingY: 7
  property real barPaddingX: 7
  property real modulesSpacing: 7
}
