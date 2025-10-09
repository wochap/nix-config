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

  StyledSlider {
    id: slider

    Layout.fillWidth: true
    from: 0
    to: 200
    stepSize: 5
    value: root.outputVolumePercentage
    snapMode: Slider.SnapAlways
    onValueChanged: {
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
