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

  StyledSlider {
    id: slider

    Layout.fillWidth: true
    from: 0
    to: 100
    stepSize: 5
    value: SBacklight.percentage
    snapMode: Slider.SnapAlways
    onValueChanged: {
      if (SBacklight.percentage === value) {
        return;
      }
      SBacklight.set(value);
    }
  }

  StyledText {
    text: `${slider.value}%`
  }
}
