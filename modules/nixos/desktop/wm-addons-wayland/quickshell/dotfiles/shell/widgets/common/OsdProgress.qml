import QtQuick
import Quickshell
import qs.services

Scope {
  id: root

  required property var service
  required property string serviceSignalName
  // should return a number between 0 and 100 (values above 100 render as over-amplified)
  required property string serviceValueKey
  property var serviceValueTransformer: value => value
  // optional service flag that renders the OSD in its muted state
  property string serviceMutedKey: ""
  property string namespace: ""
  property string icon: ""
  property string mutedIcon: ""
  property color fillColor: "transparent"
  // isOpen drives the enter/exit animation, isVisible keeps the window alive until the exit finishes
  property bool isOpen: false
  property bool isVisible: false
  property bool isReady: false

  function handleChange() {
    if (!isReady) {
      return;
    }
    SOsdProgress.requestShow(root);
    root.isOpen = true;
    root.isVisible = true;
    timer.restart();
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
    if (SOsdProgress.currentOsd === root)
      SOsdProgress.currentOsd = null;
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

    sourceComponent: OsdProgressContent {
      service: root.service
      serviceValueKey: root.serviceValueKey
      serviceMutedKey: root.serviceMutedKey
      namespace: root.namespace
      serviceValueTransformer: root.serviceValueTransformer
      icon: root.icon
      mutedIcon: root.mutedIcon
      fillColor: root.fillColor
      isOpen: root.isOpen
      onExited: {
        if (!root.isOpen)
          root.isVisible = false;
      }
    }
  }
}
