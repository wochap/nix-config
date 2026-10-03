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
    property int small: 4
    property int medium: 6
    property int windowRounding: 8
  }

  animation: QtObject {
    property int duration: 150
    property int easingType: Easing.OutCubic
    // exits are slightly faster than enters
    property int exitDuration: 120
    property int exitEasingType: Easing.InCubic
    // enter/exit offset for popovers, toasts and OSDs
    property int slideDistance: 8
  }

  // elevation shadows, used through StyledRectangularShadow
  property QtObject elevation: QtObject {
    property QtObject e1: QtObject {
      property int blur: 12
      property int offsetY: 4
      property real opacity: 0.4
    }
    property QtObject e2: QtObject {
      property int blur: 28
      property int offsetY: 10
      property real opacity: 0.55
    }
  }

  // Overlay opacities used to derive tinted fills from the palette,
  // e.g. Theme.tint(Theme.options.surface0, Theme.options.mauve, Styles.tint.selected)
  property QtObject tint: QtObject {
    property real subtle: 0.10
    property real hover: 0.16
    property real ring: 0.55
    property real selected: 0.25
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
