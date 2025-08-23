import QtQuick
import QtQuick.Effects

import qs.config

RectangularShadow {
  required property var target
  anchors.fill: target
  radius: target.radius
  blur: 21
  offset: Qt.vector2d(0.0, 0.0)
  spread: 4
  color: Theme.addAlpha(Theme.options.shadow, 0.4)
  cached: true
}
