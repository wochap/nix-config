import QtQuick
import Quickshell
import qs.services

Scope {
  id: root

  required property var service
  required property string serviceSignalName
  required property string serviceFlagKey
  property string namespace: ""
  property string iconOn: ""
  property string iconOff: ""
  property bool showIconOn: true
  property bool isOpen: false
  property bool isReady: false

  function handleChange() {
    if (!isReady) {
      return;
    }
    if (service[serviceFlagKey] || root.showIconOn) {
      SOsdStatus.requestShow(root);
      root.isOpen = true;
      timer.restart();
    } else {
      root.forceClose();
    }
  }

  function forceClose() {
    timer.stop();
    root.isOpen = false;
  }

  Component.onCompleted: {
    service[root.serviceSignalName].connect(handleChange);
  }

  Timer {
    id: timer

    interval: 1000
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
    active: root.isOpen

    sourceComponent: OsdStatusContent {
      service: root.service
      serviceFlagKey: root.serviceFlagKey
      namespace: root.namespace
      iconOn: root.iconOn
      iconOff: root.iconOff
    }
  }
}
