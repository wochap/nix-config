import QtQuick
import Quickshell

import qs.services

Scope {
  id: root

  required property var service
  required property string serviceSignalName
  // should return a number between 0 and 100
  required property string serviceValueKey
  property var serviceValueTransformer: value => value
  property string namespace: ""
  property bool isOpen: false
  property string icon: ""
  property bool isReady: false

  function handleChange() {
    if (!isReady) {
      return;
    }
    SOsd.requestShow(root);
    root.isOpen = true;
    timer.restart();
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

    sourceComponent: OsdContent {
      service: root.service
      serviceValueKey: root.serviceValueKey
      namespace: root.namespace
      serviceValueTransformer: root.serviceValueTransformer
      icon: root.icon
    }
  }
}
