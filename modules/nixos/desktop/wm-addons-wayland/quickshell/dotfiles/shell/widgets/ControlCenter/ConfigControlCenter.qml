pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config

Singleton {
  id: root

  property real controlCenterWidth: 380
  property real controlCenterPadding: 12
  property real controlCenterSpacing: 12
  // gap between the bar and the panel
  property real controlCenterMargin: 6
  property bool isBlurEnabled: Global.isBlurEnabled

  property real tileHeight: 40
  property real tileSpacing: 6
  property real tileIconSize: 32
  property real headerButtonSize: 28
  property real sliderButtonSize: 28
  property real sliderValueWidth: 44
  property real sliderSpacing: 10
  property real cardPadding: 10

  // mauve tint over the base color for tile states
  property real tileOnTint: 0.18
  property real tileOnHoverTint: 0.23
  property real tilePressedTint: 0.30
  // text tint over the base color for hovered off tiles
  property real tileOffHoverTint: 0.16
  property real disabledOpacity: 0.45
  // seconds a destructive header button stays armed waiting for the confirm click
  property int confirmTimeout: 3000
}
