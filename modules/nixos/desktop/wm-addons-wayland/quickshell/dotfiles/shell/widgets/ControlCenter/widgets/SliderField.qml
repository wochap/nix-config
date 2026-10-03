import QtQuick
import QtQuick.Layouts
import qs.config
import qs.widgets.common
import qs.widgets.ControlCenter

// 28px icon button + slider + right-aligned value
RowLayout {
  id: root

  required property string icon
  property alias value: slider.value
  property alias minimum: slider.minimum
  property alias maximum: slider.maximum
  property alias step: slider.step
  readonly property alias displayValue: slider.displayValue
  property string valueText: `${slider.displayValue}%`
  property string tooltipText: `${slider.displayValue}`
  // dimmed fill + red button, e.g. muted output
  property bool isMuted: false
  // values past this turn peach and the fill wraps to show the excess,
  // e.g. over-amplified volume
  property int overdriveFrom: -1
  property color fillColor: Theme.options.primary
  property bool isButtonInteractive: false
  readonly property bool isOverdriven: root.overdriveFrom >= 0 && slider.displayValue > root.overdriveFrom

  signal moved(int value)
  signal buttonClicked

  spacing: 8

  StyledRect {
    Layout.preferredWidth: ConfigControlCenter.sliderButtonSize
    Layout.preferredHeight: ConfigControlCenter.sliderButtonSize
    radius: width / 2
    color: {
      if (root.isMuted) {
        return Theme.addAlpha(Theme.options.red, Styles.tint.hover);
      }
      return root.isButtonInteractive && buttonMouseArea.containsMouse ? Theme.options.surface1 : Theme.options.surface0;
    }

    SystemIcon {
      enableColoriser: true
      anchors.centerIn: parent
      icon: root.icon
      size: Styles.font.pixelSize.hugeass
      color: {
        if (!root.enabled) {
          return Theme.options.surface2;
        }
        if (root.isMuted) {
          return Theme.options.red;
        }
        if (root.isOverdriven) {
          return Theme.options.peach;
        }
        return root.isButtonInteractive && buttonMouseArea.containsMouse ? Theme.options.text : Theme.options.subtext1;
      }
    }

    MouseArea {
      id: buttonMouseArea

      anchors.fill: parent
      enabled: root.isButtonInteractive
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.buttonClicked()
    }
  }

  CustomSlider {
    id: slider

    Layout.fillWidth: true
    tooltipText: root.tooltipText
    wrapAt: root.overdriveFrom
    fillColor: {
      if (!root.enabled) {
        return Theme.options.surface1;
      }
      if (root.isMuted) {
        return Theme.options.surface2;
      }
      return root.isOverdriven ? Theme.options.peach : root.fillColor;
    }
    knobColor: {
      if (!root.enabled) {
        return Theme.options.surface2;
      }
      if (root.isMuted) {
        return Theme.options.overlay1;
      }
      return root.isOverdriven ? Theme.options.peach : Theme.options.text;
    }
    onSliderValueChanged: newValue => root.moved(newValue)
  }

  StyledText {
    Layout.preferredWidth: ConfigControlCenter.sliderValueWidth
    horizontalAlignment: Text.AlignRight
    text: root.enabled ? root.valueText : "—"
    font.pixelSize: Styles.font.pixelSize.small
    font.features: {
      "tnum": 1
    }
    color: {
      if (!root.enabled) {
        return Theme.options.surface2;
      }
      if (root.isMuted) {
        return Theme.options.red;
      }
      if (root.isOverdriven) {
        return Theme.options.peach;
      }
      return slider.isActive ? Theme.options.primary : Theme.options.text;
    }
  }
}
