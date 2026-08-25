pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
  property int holdDelay: 500
  property real backgroundOpacity: 0.5
  property real panelPadding: 16
  property real rowSpacing: 10
  property real columnSpacing: 24
  property real keycapSpacing: 4
  property real minimumCellWidth: 240
}
