pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
  property int holdDelay: 500
  property real bindingBackgroundOpacity: 0.9
  property real panelPadding: 16
  property real bottomMargin: 40
  property real bindingPadding: 4
  property real rowSpacing: 8
  property real columnSpacing: 8
  property real keycapSpacing: 4
  property real keycapPadding: 4
  property real keyLaneWidth: 110
  property real maximumDescriptionWidth: 125
  property real minimumCellWidth: 260
}
