pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.config

Singleton {
  id: root

  property real barHeight: 40
  property real shadowHeight: barHeight
  property real barPaddingY: 4
  property real barPaddingX: 8
  property real modulesSpacing: 8
  property real modulesPaddingX: Styles.font.pixelSize.normal * 0.4
  property bool isBlurEnabled: Global.isBlurEnabled
  property bool isBarAtBottom: false
  property int clientIcon: 28
}
