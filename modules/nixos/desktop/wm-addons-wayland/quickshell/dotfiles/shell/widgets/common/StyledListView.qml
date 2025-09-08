import QtQuick
import qs.config

ListView {
  id: root

  property bool popIn: true

  add: Transition {
    animations: [Styles.animations.numberAnimation.createObject(this, {
        properties: root.popIn ? "opacity,scale" : "opacity",
        from: 0,
        to: 1
      })]
  }

  addDisplaced: Transition {
    animations: [Styles.animations.numberAnimation.createObject(this, {
        property: "y"
      }), Styles.animations.numberAnimation.createObject(this, {
        properties: root.popIn ? "opacity,scale" : "opacity",
        to: 1
      })]
  }

  remove: Transition {
    animations: [Styles.animations.numberAnimation.createObject(this, {
        property: "opacity",
        to: 0
      })]
  }

  removeDisplaced: Transition {
    animations: [Styles.animations.numberAnimation.createObject(this, {
        property: "y"
      }), Styles.animations.numberAnimation.createObject(this, {
        properties: root.popIn ? "opacity,scale" : "opacity",
        to: 1
      })]
  }
}
