pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets.Bluetooth
import qs.widgets.Media
import qs.widgets.Lock

// one panel at a time above the dock; switching runs the exit, then the enter
FocusScope {
  id: root

  // requested panel: bt | media | power | ""
  property string panel: ""
  // panel on screen, trails `panel` by the exit animation
  property string shown: ""

  signal closeRequested
  signal powerActionRequested(string action)

  function focusPanel() {
    loader.item?.forceActiveFocus();
  }

  implicitWidth: loader.item?.implicitWidth ?? 0
  implicitHeight: loader.item?.implicitHeight ?? 0

  onPanelChanged: switchAnimation.restart()

  SequentialAnimation {
    id: switchAnimation

    ParallelAnimation {
      NumberAnimation {
        target: loader
        property: "opacity"
        to: 0
        duration: root.shown !== "" ? Styles.animation.exitDuration : 0
        easing.type: Styles.animation.exitEasingType
      }
      NumberAnimation {
        target: shift
        property: "y"
        to: Styles.animation.slideDistance
        duration: root.shown !== "" ? Styles.animation.exitDuration : 0
        easing.type: Styles.animation.exitEasingType
      }
    }
    ScriptAction {
      script: root.shown = root.panel
    }
    ParallelAnimation {
      NumberAnimation {
        target: loader
        property: "opacity"
        to: 1
        duration: Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
      NumberAnimation {
        target: shift
        property: "y"
        to: 0
        duration: Styles.animation.duration
        easing.type: Styles.animation.easingType
      }
    }
  }

  // a click on a panel's background must not reach the surface, it closes panels
  MouseArea {
    anchors.fill: loader
    visible: loader.item !== null
  }

  Loader {
    id: loader

    anchors {
      right: parent.right
      bottom: parent.bottom
    }
    focus: true
    opacity: 0
    active: root.shown !== ""
    sourceComponent: {
      switch (root.shown) {
      case "bt":
        return bluetoothComponent;
      case "media":
        return mediaComponent;
      case "power":
        return powerComponent;
      default:
        return null;
      }
    }
    onLoaded: loader.item.forceActiveFocus()

    transform: Translate {
      id: shift

      y: Styles.animation.slideDistance
    }
  }

  Component {
    id: bluetoothComponent

    BluetoothPanel {
      implicitWidth: ConfigLock.panelWidth
      implicitHeight: ConfigLock.bluetoothPanelHeight
      ink: ConfigLock.ink
      subtext: ConfigLock.subtext
      overlay: ConfigLock.overlay
      fieldBorder: ConfigLock.fieldBorder
      scanDuration: ConfigLock.scanDuration
      connectTimeout: ConfigLock.connectTimeout
      onCloseRequested: root.closeRequested()
    }
  }

  Component {
    id: mediaComponent

    MediaCard {
      panel: true
      ink: ConfigLock.ink
      onCloseRequested: root.closeRequested()
    }
  }

  Component {
    id: powerComponent

    PowerPanel {
      onCloseRequested: root.closeRequested()
      onActionRequested: action => root.powerActionRequested(action)
    }
  }
}
