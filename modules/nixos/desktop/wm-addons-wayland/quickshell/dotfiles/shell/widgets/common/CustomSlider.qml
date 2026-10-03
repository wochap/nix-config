import QtQuick
import qs.config

// Flat slider: 6px track, 14px knob with a 3px ring, value pill while hovered or dragged
Item {
  id: slider

  // --- Public Properties ---
  property int value: 50
  property int minimum: 0
  property int maximum: 100
  property int step: 1
  property bool isDragging: false
  // value picked by the user, shown until the backing service catches up,
  // so `value` can stay bound to the service
  property bool hasPendingValue: false
  property int pendingValue: 0
  readonly property int displayValue: hasPendingValue ? pendingValue : value
  // when set, values past it wrap: the fill restarts from 0 and covers
  // wrapAt..maximum, e.g. over-amplified volume (0-100 then 100-200)
  property int wrapAt: -1
  readonly property bool hasWrap: wrapAt > minimum && wrapAt < maximum
  readonly property bool isWrapped: hasWrap && displayValue > wrapAt
  // range the track currently represents, fixed while dragging so the
  // knob doesn't jump between laps mid-drag
  property bool dragLapIsWrapped: false
  readonly property bool lapIsWrapped: isDragging ? dragLapIsWrapped : isWrapped
  readonly property int lapMinimum: hasWrap && lapIsWrapped ? wrapAt : minimum
  readonly property int lapMaximum: hasWrap && !lapIsWrapped ? wrapAt : maximum

  // --- Theme Mappings ---
  property color trackColor: Theme.options.surface1
  property color fillColor: enabled ? Theme.options.primary : Theme.options.surface1
  property color knobColor: enabled ? Theme.options.text : Theme.options.surface2
  // color of the 3px ring around the knob, should match what is behind the slider
  property color ringColor: Theme.options.background
  property bool showTooltip: true
  property string tooltipText: `${slider.displayValue}`

  readonly property real ratio: {
    const range = slider.lapMaximum - slider.lapMinimum;
    return range === 0 ? 0 : Math.max(0, Math.min(1, (slider.displayValue - slider.lapMinimum) / range));
  }
  readonly property bool isActive: sliderMouseArea.containsMouse || sliderMouseArea.pressed || slider.isDragging

  signal sliderValueChanged(int newValue)
  signal sliderDragFinished(int finalValue)

  implicitWidth: 200
  implicitHeight: 28

  function updateValueFromPosition(x) {
    // pushing past an edge while dragging moves to the other lap
    if (isDragging && hasWrap) {
      if (!dragLapIsWrapped && x > sliderTrack.width + 24) {
        dragLapIsWrapped = true;
      } else if (dragLapIsWrapped && x < -24) {
        dragLapIsWrapped = false;
      }
    }
    const ratio = Math.max(0, Math.min(1, x / sliderTrack.width));
    const rawValue = lapMinimum + ratio * (lapMaximum - lapMinimum);
    let newValue = step > 1 ? Math.round(rawValue / step) * step : Math.round(rawValue);
    setPendingValue(newValue);
  }

  function setPendingValue(newValue) {
    newValue = Math.max(minimum, Math.min(maximum, newValue));
    if (newValue === displayValue) {
      return;
    }
    pendingValue = newValue;
    hasPendingValue = true;
    pendingTimer.restart();
    sliderValueChanged(newValue);
  }

  // drop the pending value once the service had time to report back
  Timer {
    id: pendingTimer

    interval: 500
    onTriggered: {
      if (!slider.isDragging) {
        slider.hasPendingValue = false;
      }
    }
  }

  StyledRect {
    id: sliderTrack

    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
      leftMargin: knob.width / 2
      rightMargin: knob.width / 2
    }
    height: 6
    radius: height / 2
    color: slider.trackColor

    StyledRect {
      id: sliderFill

      anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
        leftMargin: -knob.width / 2
      }
      width: sliderTrack.width * slider.ratio + knob.width / 2
      radius: height / 2
      color: slider.fillColor

      Behavior on width {
        enabled: !slider.isDragging

        NumberAnimation {
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      }
    }

    // hover / drag halo
    Rectangle {
      anchors.centerIn: knob
      width: knob.width + 14
      height: width
      radius: width / 2
      color: Theme.addAlpha(slider.fillColor, Styles.tint.selected)
      opacity: slider.enabled && slider.isActive ? 1 : 0
      visible: opacity > 0

      Behavior on opacity {
        NumberAnimation {
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      }
    }

    Rectangle {
      id: knob

      x: sliderFill.width - knob.width
      anchors.verticalCenter: parent.verticalCenter
      width: 14
      height: 14
      radius: width / 2
      color: slider.knobColor
      border {
        width: 0
      }

      // 3px ring that cuts the knob out of the track
      Rectangle {
        z: -1
        anchors.centerIn: parent
        width: parent.width + 6
        height: width
        radius: width / 2
        color: slider.ringColor
      }
    }

    // value pill
    Rectangle {
      anchors {
        horizontalCenter: knob.horizontalCenter
        bottom: knob.top
        bottomMargin: 9
      }
      z: 10
      height: 20
      width: Math.max(height, tooltipLabel.implicitWidth + 12)
      radius: height / 2
      color: Theme.options.primary
      opacity: slider.showTooltip && slider.enabled && slider.isActive ? 1 : 0
      visible: opacity > 0

      Behavior on opacity {
        NumberAnimation {
          duration: Styles.animation.duration
          easing.type: Styles.animation.easingType
        }
      }

      StyledText {
        id: tooltipLabel

        anchors.centerIn: parent
        text: slider.tooltipText
        color: Theme.options.crust
        font.pixelSize: Styles.font.pixelSize.smaller
        font.weight: Font.Bold
      }
    }

    MouseArea {
      id: sliderMouseArea

      anchors.fill: parent
      anchors.topMargin: -11
      anchors.bottomMargin: -11
      anchors.leftMargin: -knob.width / 2
      anchors.rightMargin: -knob.width / 2
      hoverEnabled: true
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      enabled: slider.enabled
      preventStealing: true
      acceptedButtons: Qt.LeftButton
      onPressed: mouse => {
        slider.dragLapIsWrapped = slider.isWrapped;
        slider.isDragging = true;
        slider.updateValueFromPosition(mouse.x - knob.width / 2);
      }
      onReleased: {
        slider.isDragging = false;
        pendingTimer.restart();
        slider.sliderDragFinished(slider.displayValue);
      }
      onPositionChanged: mouse => {
        if (pressed && slider.isDragging) {
          slider.updateValueFromPosition(mouse.x - knob.width / 2);
        }
      }
      onWheel: wheel => {
        const direction = wheel.angleDelta.y > 0 ? 1 : -1;
        slider.setPendingValue(slider.displayValue + direction * Math.max(1, slider.step));
      }
    }
  }
}
