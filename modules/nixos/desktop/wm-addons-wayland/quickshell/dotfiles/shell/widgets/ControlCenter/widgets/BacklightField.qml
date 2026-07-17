import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

RowLayout {
  id: root

  spacing: 16

  MaterialIcon {
    icon: "sunny"
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
    value: SBacklight.percentage
    onSliderValueChanged: {
      if (SBacklight.percentage === value) {
        return;
      }
      SBacklight.set(value);
    }
  }

  StyledText {
    text: (`${slider.value}%`).padStart(4, ' ')
  }
}
