import QtQuick
import QtQuick.Effects
import qs.config

RectangularShadow {
  required property var target
  // optional Styles.elevation.* level, falls back to the legacy shadow
  property QtObject elevation: null

  anchors.fill: target
  radius: target.radius
  blur: elevation ? elevation.blur : 20
  offset: Qt.vector2d(0.0, elevation ? elevation.offsetY : 0.0)
  spread: elevation ? 0 : 10
  color: Theme.addAlpha(Theme.options.shadow, elevation ? elevation.opacity : 0.4)
  cached: true
}
