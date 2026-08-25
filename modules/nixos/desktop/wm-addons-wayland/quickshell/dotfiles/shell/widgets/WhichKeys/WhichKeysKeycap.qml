import QtQuick
import QtQuick.Effects
import qs.config
import qs.widgets.common

Rectangle {
  id: root

  required property string label
  property real sizeMultiplier: 1
  property color borderColor: Theme.options.primary
  readonly property real horizontalPadding: (label.length > 1 ? 8 : ConfigWhichKeys.keycapPadding) * sizeMultiplier

  implicitHeight: keyLabel.implicitHeight + 2 * ConfigWhichKeys.keycapPadding * sizeMultiplier
  implicitWidth: Math.max(implicitHeight, keyLabel.implicitWidth + 2 * horizontalPadding)
  radius: 4
  color: Theme.options.backgroundOverlay
  border {
    width: 1
    color: root.borderColor
  }
  layer.enabled: true
  layer.effect: MultiEffect {
    shadowEnabled: true
    shadowBlur: 0.5
    shadowColor: Theme.options.shadow
  }

  StyledText {
    id: keyLabel

    anchors.centerIn: parent
    text: root.label
    color: Theme.options.primary
    font.pixelSize: Styles.font.pixelSize.small * root.sizeMultiplier
    font.weight: Font.Bold
  }
}
