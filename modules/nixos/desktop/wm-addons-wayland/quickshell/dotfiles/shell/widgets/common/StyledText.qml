import QtQuick
import qs.config

Text {
  renderType: Text.NativeRendering
  verticalAlignment: Text.AlignVCenter
  color: Theme.options.text
  linkColor: Theme.options.primary
  font {
    family: Styles.font.family.main
    pixelSize: Styles.font.pixelSize.normal
    hintingPreference: Font.PreferFullHinting
  }

  Behavior on color {
    animation: Styles.animations.colorAnimation.createObject(this)
  }
}
