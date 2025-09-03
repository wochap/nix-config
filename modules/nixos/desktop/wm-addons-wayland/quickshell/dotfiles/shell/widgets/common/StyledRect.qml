import QtQuick
import qs.config

Rectangle {
  id: root

  color: "transparent"

  Behavior on color {
    ColorAnimation {
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
  }
}
