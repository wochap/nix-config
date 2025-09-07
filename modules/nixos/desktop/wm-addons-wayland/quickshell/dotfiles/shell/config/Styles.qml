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

  // animations: QtObject {
  //   property QtObject elementMove: QtObject {
  //     property int duration: root.animationCurves.expressiveDefaultSpatialDuration
  //     property int type: Easing.BezierSpline
  //     property list<real> bezierCurve: root.animationCurves.expressiveDefaultSpatial
  //     property int velocity: 650
  //     property Component numberAnimation: Component {
  //       NumberAnimation {
  //         duration: root.animation.elementMove.duration
  //         easing.type: root.animation.elementMove.type
  //         easing.bezierCurve: root.animation.elementMove.bezierCurve
  //       }
  //     }
  //     property Component colorAnimation: Component {
  //       ColorAnimation {
  //         duration: root.animation.elementMove.duration
  //         easing.type: root.animation.elementMove.type
  //         easing.bezierCurve: root.animation.elementMove.bezierCurve
  //       }
  //     }
  //   }
  //   property QtObject elementMoveEnter: QtObject {
  //     property int duration: 400
  //     property int type: Easing.BezierSpline
  //     property list<real> bezierCurve: root.animationCurves.emphasizedDecel
  //     property int velocity: 650
  //     property Component numberAnimation: Component {
  //       NumberAnimation {
  //         duration: root.animation.elementMoveEnter.duration
  //         easing.type: root.animation.elementMoveEnter.type
  //         easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
  //       }
  //     }
  //   }
  //   property QtObject elementMoveExit: QtObject {
  //     property int duration: 200
  //     property int type: Easing.BezierSpline
  //     property list<real> bezierCurve: root.animationCurves.emphasizedAccel
  //     property int velocity: 650
  //     property Component numberAnimation: Component {
  //       NumberAnimation {
  //         duration: root.animation.elementMoveExit.duration
  //         easing.type: root.animation.elementMoveExit.type
  //         easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
  //       }
  //     }
  //   }
  //   property QtObject elementMoveFast: QtObject {
  //     property int duration: root.animationCurves.expressiveEffectsDuration
  //     property int type: Easing.BezierSpline
  //     property list<real> bezierCurve: root.animationCurves.expressiveEffects
  //     property int velocity: 850
  //     property Component colorAnimation: Component {
  //       ColorAnimation {
  //         duration: root.animation.elementMoveFast.duration
  //         easing.type: root.animation.elementMoveFast.type
  //         easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
  //       }
  //     }
  //     property Component numberAnimation: Component {
  //       NumberAnimation {
  //         duration: root.animation.elementMoveFast.duration
  //         easing.type: root.animation.elementMoveFast.type
  //         easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
  //       }
  //     }
  //   }
  //   property QtObject clickBounce: QtObject {
  //     property int duration: 200
  //     property int type: Easing.BezierSpline
  //     property list<real> bezierCurve: root.animationCurves.expressiveFastSpatial
  //     property int velocity: 850
  //     property Component numberAnimation: Component {
  //       NumberAnimation {
  //         duration: root.animation.clickBounce.duration
  //         easing.type: root.animation.clickBounce.type
  //         easing.bezierCurve: root.animation.clickBounce.bezierCurve
  //       }
  //     }
  //   }
  //   property QtObject scroll: QtObject {
  //     property int duration: 200
  //     property int type: Easing.BezierSpline
  //     property list<real> bezierCurve: root.animationCurves.standardDecel
  //   }
  //   property QtObject menuDecel: QtObject {
  //     property int duration: 350
  //     property int type: Easing.OutExpo
  //   }
  // }
}
