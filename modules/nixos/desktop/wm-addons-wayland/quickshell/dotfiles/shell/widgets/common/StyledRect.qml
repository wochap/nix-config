import QtQuick
import qs.config

Rectangle {
  id: root

  color: "transparent"

  Behavior on color {
    animation: Styles.animations.colorAnimation.createObject(this)
  }
}
