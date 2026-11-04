pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  property real barWidth: 44
  property real shadowWidth: 20
  property real barPaddingX: 4
  property real barPaddingY: 8
  property real modulesRadius: 8
  property real modulesSpacing: 8
  property real modulesPaddingY: 4
  property bool isBlurEnabled: Global.isBlurEnabled

  // Status and client count modules (top and bottom zones)
  property int statusIconSize: 19
  property int statusFontSize: 10

  // Tray button on rail: 36×24 · r12 · icon 18 (matches 36px width of VControl)
  property real trayButtonWidth: 36
  property real trayButtonHeight: 24
  property real trayButtonRadius: 12
  property int trayButtonIconSize: 18

  // Tray popover: 3 columns · 28×28 circular chips · r14 · icon 16
  property real trayItemSize: 28
  property real trayItemRadius: 14
  property int trayItemIconSize: 16
}
