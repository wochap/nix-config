import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

RowLayout {
  id: root

  property int outputVolumePercentage: Math.round(SPipewire.outputVolume * 100)

  spacing: 16

  MaterialIcon {
    icon: "speaker"
    size: Styles.font.pixelSize.huge
    weight: Font.Light
  }

  CustomSlider {
    id: slider

    Layout.fillWidth: true
    implicitHeight: 2
    minimum: 0
    maximum: 200
    step: 5
    value: root.outputVolumePercentage
    onSliderValueChanged: {
      if (root.outputVolumePercentage === value) {
        return;
      }
      SPipewire.setOutputVolume(value);
    }
  }

  StyledText {
    text: (`${slider.value}%`).padStart(4, ' ')
  }
}
