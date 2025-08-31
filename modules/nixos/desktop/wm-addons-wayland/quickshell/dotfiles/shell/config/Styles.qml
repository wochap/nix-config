pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
  id: root

  property QtObject font
  property QtObject rounding
  property QtObject animationCurves
  property QtObject animation

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

  rounding: QtObject {
    property int unsharpen: 2
    property int unsharpenmore: 6
    property int verysmall: 8
    property int small: 12
    property int normal: 17
    property int large: 23
    property int verylarge: 30
    property int full: 9999
    property int screenRounding: large
    property int windowRounding: 18
  }

  animationCurves: QtObject {
    readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.90, 1, 1] // Default, 350ms
    readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1] // Default, 500ms
    readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1] // Default, 650ms
    readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1] // Default, 200ms
    readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> emphasizedFirstHalf: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82]
    readonly property list<real> emphasizedLastHalf: [5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
    readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    readonly property real expressiveFastSpatialDuration: 350
    readonly property real expressiveDefaultSpatialDuration: 500
    readonly property real expressiveSlowSpatialDuration: 650
    readonly property real expressiveEffectsDuration: 200
  }

  animation: QtObject {
    property QtObject elementMove: QtObject {
      property int duration: root.animationCurves.expressiveDefaultSpatialDuration
      property int type: Easing.BezierSpline
      property list<real> bezierCurve: root.animationCurves.expressiveDefaultSpatial
      property int velocity: 650
      property Component numberAnimation: Component {
        NumberAnimation {
          duration: root.animation.elementMove.duration
          easing.type: root.animation.elementMove.type
          easing.bezierCurve: root.animation.elementMove.bezierCurve
        }
      }
      property Component colorAnimation: Component {
        ColorAnimation {
          duration: root.animation.elementMove.duration
          easing.type: root.animation.elementMove.type
          easing.bezierCurve: root.animation.elementMove.bezierCurve
        }
      }
    }
    property QtObject elementMoveEnter: QtObject {
      property int duration: 400
      property int type: Easing.BezierSpline
      property list<real> bezierCurve: root.animationCurves.emphasizedDecel
      property int velocity: 650
      property Component numberAnimation: Component {
        NumberAnimation {
          duration: root.animation.elementMoveEnter.duration
          easing.type: root.animation.elementMoveEnter.type
          easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
        }
      }
    }
    property QtObject elementMoveExit: QtObject {
      property int duration: 200
      property int type: Easing.BezierSpline
      property list<real> bezierCurve: root.animationCurves.emphasizedAccel
      property int velocity: 650
      property Component numberAnimation: Component {
        NumberAnimation {
          duration: root.animation.elementMoveExit.duration
          easing.type: root.animation.elementMoveExit.type
          easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
        }
      }
    }
    property QtObject elementMoveFast: QtObject {
      property int duration: root.animationCurves.expressiveEffectsDuration
      property int type: Easing.BezierSpline
      property list<real> bezierCurve: root.animationCurves.expressiveEffects
      property int velocity: 850
      property Component colorAnimation: Component {
        ColorAnimation {
          duration: root.animation.elementMoveFast.duration
          easing.type: root.animation.elementMoveFast.type
          easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
        }
      }
      property Component numberAnimation: Component {
        NumberAnimation {
          duration: root.animation.elementMoveFast.duration
          easing.type: root.animation.elementMoveFast.type
          easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
        }
      }
    }
    property QtObject clickBounce: QtObject {
      property int duration: 200
      property int type: Easing.BezierSpline
      property list<real> bezierCurve: root.animationCurves.expressiveFastSpatial
      property int velocity: 850
      property Component numberAnimation: Component {
        NumberAnimation {
          duration: root.animation.clickBounce.duration
          easing.type: root.animation.clickBounce.type
          easing.bezierCurve: root.animation.clickBounce.bezierCurve
        }
      }
    }
    property QtObject scroll: QtObject {
      property int duration: 200
      property int type: Easing.BezierSpline
      property list<real> bezierCurve: root.animationCurves.standardDecel
    }
    property QtObject menuDecel: QtObject {
      property int duration: 350
      property int type: Easing.OutExpo
    }
  }
}
