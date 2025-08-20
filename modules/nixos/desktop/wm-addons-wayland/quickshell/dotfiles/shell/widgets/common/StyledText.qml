import QtQuick

import qs.config

Text {
  renderType: Text.NativeRendering
  verticalAlignment: Text.AlignVCenter
  font {
    hintingPreference: Font.PreferFullHinting
    family: Styles?.font.family.main
    pixelSize: Styles?.font.pixelSize.normal
  }
  color: Theme.options.text
  linkColor: Theme.options.primary
}
