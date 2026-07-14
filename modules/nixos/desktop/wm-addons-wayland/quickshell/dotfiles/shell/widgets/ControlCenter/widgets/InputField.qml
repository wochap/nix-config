import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

RowLayout {
  id: root

  property int inputVolumePercentage: Math.round(SPipewire.inputVolume * 100)

  spacing: 16

  MaterialIcon {
    icon: "mic"
    size: Styles.font.pixelSize.huge
    weight: Font.Light
  }

  CustomSlider {
    id: slider

    Layout.fillWidth: true
    implicitHeight: 2
    minimum: 0
    maximum: 100
    step: 5
    value: root.inputVolumePercentage
    onSliderValueChanged: {
      if (root.inputVolumePercentage === value) {
        return;
      }
      SPipewire.setInputVolume(value);
    }
  }

  StyledText {
    text: (`${slider.value}%`).padStart(4, ' ')
  }
}
