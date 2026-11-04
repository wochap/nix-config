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
  property real modulesRadius: 4
  property real modulesSpacing: 8
  property real modulesPaddingX: 6
  property bool isBlurEnabled: Global.isBlurEnabled

  // Status and client count modules
  property int statusIconSize: 19
  property int statusFontSize: 10

  property real trayButtonWidth: 36
  property real trayButtonHeight: 32
  property real trayButtonRadius: 16
  property real trayButtonIconSize: 18
  property real trayItemSize: 28
  property real trayItemRadius: 14
  property real trayItemIconSize: 16
}
