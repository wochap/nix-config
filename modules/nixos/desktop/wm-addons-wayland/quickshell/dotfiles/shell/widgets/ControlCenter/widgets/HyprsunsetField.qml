import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets.common

RowLayout {
  id: root

  property bool hasCompleted: false

  spacing: 16

  Component.onCompleted: {
    SHyprsunset.getState();
    root.hasCompleted = true;
  }

  MaterialIcon {
    icon: "moon_stars"
    size: Styles.font.pixelSize.huge
    weight: Font.Light
  }

  StyledSlider {
    id: slider

    Layout.fillWidth: true
    from: 3000
    to: 6500
    stepSize: 100
    value: SHyprsunset.temperature
    snapMode: Slider.SnapAlways
    onValueChanged: {
      if (!root.hasCompleted || value === 0) {
        return;
      }
      SHyprsunset.setTemperature(value);
    }
  }

  StyledText {
    text: slider.value
  }
}
