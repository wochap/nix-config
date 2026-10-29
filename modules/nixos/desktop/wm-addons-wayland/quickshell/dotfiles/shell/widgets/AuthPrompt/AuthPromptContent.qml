import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets.AuthPrompt

// full screen dimmed overlay on the monitor focused when the first prompt arrived
PanelWindow {
  id: root

  screen: Quickshell.screens.find(s => s.name === SAuth.screenName) ?? null
  WlrLayershell.namespace: "quickshell:auth"
  // read by qs.Woints SHints, the attached WlrLayershell is not reachable from JS
  readonly property string namespace: WlrLayershell.namespace
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: SAuth.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  anchors {
    top: true
    left: true
    bottom: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"

  Rectangle {
    id: scrim

    anchors.fill: parent
    color: Theme.addAlpha(Theme.options.crust, ConfigAuth.scrimOpacity)
    opacity: 0

    // a stray click must not dismiss a password prompt
    MouseArea {
      anchors.fill: parent
      enabled: SAuth.isOpen
    }
  }

  AuthDialog {
    id: dialog

    anchors.centerIn: parent
    focus: true
    opacity: 0
    scale: 0.96
  }

  ParallelAnimation {
    id: enterAnimation

    running: true

    NumberAnimation {
      target: scrim
      property: "opacity"
      to: 1
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
    NumberAnimation {
      target: dialog
      properties: "opacity,scale"
      to: 1
      duration: Styles.animation.duration
      easing.type: Styles.animation.easingType
    }
  }

  ParallelAnimation {
    id: exitAnimation

    NumberAnimation {
      target: scrim
      property: "opacity"
      to: 0
      duration: Styles.animation.exitDuration
      easing.type: Styles.animation.exitEasingType
    }
    NumberAnimation {
      target: dialog
      property: "opacity"
      to: 0
      duration: Styles.animation.exitDuration
      easing.type: Styles.animation.exitEasingType
    }
    NumberAnimation {
      target: dialog
      property: "scale"
      to: 0.96
      duration: Styles.animation.exitDuration
      easing.type: Styles.animation.exitEasingType
    }
    onStopped: {
      if (!SAuth.isOpen) {
        SAuth.finalizeClose();
      }
    }
  }

  Connections {
    target: SAuth

    function onIsOpenChanged() {
      if (SAuth.isOpen) {
        exitAnimation.stop();
        enterAnimation.start();
      } else {
        enterAnimation.stop();
        exitAnimation.start();
      }
    }
  }
}
