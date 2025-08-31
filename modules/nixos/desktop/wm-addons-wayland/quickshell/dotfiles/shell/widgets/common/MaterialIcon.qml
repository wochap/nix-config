import QtQuick
import qs.config

Text {
  id: root

  property string weight: Font.ExtraLight
  required property string icon
  property int size: Styles?.font.pixelSize.normal
  property real fill: 0 // 0 or 1
  readonly property real truncatedFill: Math.round(fill * 100) / 100 // Reduce memory consumption spikes from constant font remapping

  renderType: Text.NativeRendering
  verticalAlignment: Text.AlignVCenter
  color: Theme.options.text
  text: icon

  font {
    family: Styles?.font.family.materialIcon
    pixelSize: size
    weight: root.weight
    hintingPreference: Font.PreferFullHinting
    variableAxes: {
      "FILL": truncatedFill,
      "opsz": fontInfo.pixelSize,
      "wght": fontInfo.weight,
      "GRAD": 0
    }
  }
}
