pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.config

Singleton {
  id: root

  property real barHeight: 40
  property real shadowHeight: 40
  property real barPaddingY: 7
  property real barPaddingX: 7
  property real modulesSpacing: 7
  property real modulesPaddingX: Styles.font.pixelSize.normal * 0.4
  property bool isBlurEnabled: Global.isBlurEnabled
  property bool isBarAtBottom: false
}
