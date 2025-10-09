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

  StyledSlider {
    id: slider

    Layout.fillWidth: true
    from: 0
    to: 100
    stepSize: 5
    value: root.inputVolumePercentage
    snapMode: Slider.SnapAlways
    onValueChanged: {
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
