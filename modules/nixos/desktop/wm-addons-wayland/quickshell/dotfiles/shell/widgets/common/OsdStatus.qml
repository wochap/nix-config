import QtQuick
import Quickshell
import qs.config
import qs.services

Scope {
  id: root

  required property var service
  required property string serviceSignalName
  required property string serviceFlagKey
  property string namespace: ""
  property string iconOn: ""
  property string iconOff: ""
  property string systemIconOn: ""
  property string systemIconOff: ""
  property color colorOn: Theme.options.peach
  property color colorOff: Theme.options.text
  property bool showIconOn: true
  // isOpen drives the enter/exit animation, isVisible keeps the window alive until the exit finishes
  property bool isOpen: false
  property bool isVisible: false
  property bool isReady: false

  function handleChange() {
    if (!isReady) {
      return;
    }
    if (service[serviceFlagKey] || root.showIconOn) {
      SOsdStatus.requestShow(root);
      root.isOpen = true;
      root.isVisible = true;
      timer.restart();
    } else {
      // flag turned off: fade out instead of showing the off state
      timer.stop();
      root.isOpen = false;
    }
  }

  function forceClose() {
    timer.stop();
    root.isOpen = false;
    root.isVisible = false;
  }

  Component.onCompleted: {
    service[root.serviceSignalName].connect(handleChange);
  }
  Component.onDestruction: {
    service[root.serviceSignalName].disconnect(handleChange);
    if (SOsdStatus.currentOsd === root)
      SOsdStatus.currentOsd = null;
  }

  Timer {
    id: timer

    interval: 1200
    repeat: false
    running: false
    onTriggered: {
      root.isOpen = false;
    }
  }

  // HACK: don't show initial state
  Timer {
    id: readyTimer

    interval: 100
    repeat: false
    running: true
    onTriggered: {
      root.isReady = true;
    }
  }

  Loader {
    active: root.isVisible

    sourceComponent: OsdStatusContent {
      service: root.service
      serviceFlagKey: root.serviceFlagKey
      namespace: root.namespace
      iconOn: root.iconOn
      iconOff: root.iconOff
      systemIconOn: root.systemIconOn
      systemIconOff: root.systemIconOff
      colorOn: root.colorOn
      colorOff: root.colorOff
      isOpen: root.isOpen
      onExited: {
        if (!root.isOpen)
          root.isVisible = false;
      }
    }
  }
}
