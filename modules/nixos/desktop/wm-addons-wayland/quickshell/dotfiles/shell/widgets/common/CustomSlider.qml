import QtQuick
import qs.config

Item {
  id: slider

  // --- Public Properties ---
  property int value: 50
  property int minimum: 0
  property int maximum: 100
  property int step: 1
  property bool isDragging: false

  // --- Theme Mappings ---
  property color thumbOutlineColor: Theme.options.surface0
  property color trackColor: enabled ? Theme.options.border : Theme.options.surface1
  property real trackOpacity: 1.0

  signal sliderValueChanged(int newValue)
  signal sliderDragFinished(int finalValue)

  height: 48
  width: parent ? parent.width : 200 // Fallback width

  function updateValueFromPosition(x) {
    let ratio = Math.max(0, Math.min(1, (x - sliderHandle.width / 2) / (sliderTrack.width - sliderHandle.width)));
    let rawValue = minimum + ratio * (maximum - minimum);
    let newValue = step > 1 ? Math.round(rawValue / step) * step : Math.round(rawValue);
    newValue = Math.max(minimum, Math.min(maximum, newValue));

    if (newValue !== value) {
      value = newValue;
      sliderValueChanged(newValue);
    }
  }

  StyledRect {
    id: sliderTrack

    width: parent.width
    height: 12
    radius: Styles.radius.windowRounding
    color: Theme.addAlpha(slider.trackColor, slider.trackOpacity)
    anchors.verticalCenter: parent.verticalCenter
    clip: false

    StyledRect {
      id: sliderFill
      height: parent.height
      radius: Styles.radius.windowRounding
      topRightRadius: 0
      bottomRightRadius: 0
      width: {
        const range = slider.maximum - slider.minimum;
        const ratio = range === 0 ? 0 : (slider.value - slider.minimum) / range;
        const travel = sliderTrack.width - sliderHandle.width;
        const handleLeft = travel * ratio;
        const endPoint = handleLeft - 3;
        return Math.max(0, Math.min(sliderTrack.width, endPoint));
      }
      color: slider.enabled ? Theme.options.primary : Theme.addAlpha(Theme.options.text, 0.12)
    }

    StyledRect {
      id: sliderHandle

      property bool active: sliderMouseArea.containsMouse || sliderMouseArea.pressed || slider.isDragging

      width: 4
      height: 20
      radius: Styles.radius.windowRounding
      x: {
        const range = slider.maximum - slider.minimum;
        const ratio = range === 0 ? 0 : (slider.value - slider.minimum) / range;
        const travel = sliderTrack.width - width;
        return Math.max(0, Math.min(travel, travel * ratio));
      }
      anchors.verticalCenter: parent.verticalCenter
      color: slider.enabled ? Theme.options.primary : Theme.addAlpha(Theme.options.text, 0.12)
      border.width: 0
      border.color: slider.thumbOutlineColor

      StyledRect {
        anchors.fill: parent
        radius: Styles.radius.windowRounding
        color: Theme.options.base
        opacity: slider.enabled ? (sliderMouseArea.pressed ? 0.16 : (sliderMouseArea.containsMouse ? 0.08 : 0)) : 0
        visible: opacity > 0
      }

      StyledRect {
        anchors.centerIn: parent
        width: parent.width + 20
        height: parent.height + 20
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.options.primary
        opacity: slider.enabled && slider.focus ? 0.3 : 0
        visible: opacity > 0
      }

      scale: active ? 1.05 : 1.0

      Behavior on scale {
        NumberAnimation {
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      }
    }

    MouseArea {
      id: sliderMouseArea

      property bool isDragging: false

      anchors.fill: parent
      anchors.topMargin: -10
      anchors.bottomMargin: -10
      hoverEnabled: true
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      enabled: slider.enabled
      preventStealing: true
      acceptedButtons: Qt.LeftButton
      onPressed: mouse => {
        if (slider.enabled) {
          slider.isDragging = true;
          sliderMouseArea.isDragging = true;
          updateValueFromPosition(mouse.x);
        }
      }
      onReleased: {
        if (slider.enabled) {
          slider.isDragging = false;
          sliderMouseArea.isDragging = false;
          slider.sliderDragFinished(slider.value);
        }
      }
      onPositionChanged: mouse => {
        if (pressed && slider.isDragging && slider.enabled) {
          updateValueFromPosition(mouse.x);
        }
      }
      onClicked: mouse => {
        if (slider.enabled && !slider.isDragging) {
          updateValueFromPosition(mouse.x);
        }
      }
    }
  }
}
