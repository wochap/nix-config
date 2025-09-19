import QtQuick
import qs.config

ListView {
  id: root

  property bool popIn: true

  add: Transition {
    animations: [Styles.animations.numberAnimation.createObject(this, {
        properties: root.popIn ? "scale,opacity" : "opacity",
        from: 0,
        to: 1
      })]
  }

  remove: Transition {
    animations: [Styles.animations.numberAnimation.createObject(this, {
        properties: root.popIn ? "scale,opacity" : "opacity",
        from: 1,
        to: 0
      })]
  }

  // handles move, addDisplaced, removeDisplaced
  displaced: Transition {
    animations: [Styles.animations.numberAnimation.createObject(this, {
        property: "y"
      }), Styles.animations.numberAnimation.createObject(this, {
        properties: root.popIn ? "scale,opacity" : "opacity",
        to: 1
      })]
  }
}
