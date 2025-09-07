pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
  id: root

  property QtObject font
  property QtObject radius
  property QtObject animation
  property QtObject animations

  font: QtObject {
    property QtObject family: QtObject {
      property string main: "Iosevka NF"
      property string materialIcon: "Material Symbols Rounded"
      property string woosIcon: "woos"
    }
    property QtObject pixelSize: QtObject {
      property int smallest: 8
      property int smaller: 10
      property int small: 12
      property int normal: 14
      property int large: 16
      property int larger: 18
      property int huge: 22
      property int hugeass: 24
      property int title: huge
    }
  }

  radius: QtObject {
    property int full: 9999
    property int windowRounding: 8
  }

  animation: QtObject {
    property int duration: 150
    property int easingType: Easing.OutCubic
  }

  animations: QtObject {
    property Component numberAnimation: Component {
      NumberAnimation {
        duration: animation.duration
        easing.type: animation.easingType
      }
    }
    property Component colorAnimation: Component {
      ColorAnimation {
        duration: animation.duration
        easing.type: animation.easingType
      }
    }
  }
}
